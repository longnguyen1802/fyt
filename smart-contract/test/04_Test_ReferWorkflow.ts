import {expect} from 'chai';
import {ethers} from 'hardhat';
import {BigNumber, Signer} from 'ethers';
import {Cryptography, MemberAccount, Protocol, ReferMixer, MoneyMixer} from '../typechain-types';
import {ProtocolParams, setupProtocol, setUpInitialMemberAndStart, AccountParams} from './helpers/setup';
import {getRandomBigNumber, modPower} from './utils/Math';
import {generateElgamaSignature} from './utils/SignatureGen';
import {deployMemberAccount, generateMemberAccountParams} from './helpers/deploy';
import {
  p,
  q,
  g,
  protocolFee,
  joinFee,
  referPhaseLength,
  moneyPhaseLength,
  signerDepositFee,
  roundLong,
} from './utils/Constant';
import {advanceBlockTo, getCurrentBlockNumber} from './utils/Time';

describe('ReferWorkflow', () => {
  // Protocol params
  let params: ProtocolParams;
  // Constant just for testing

  let protocol: Protocol;
  let cryptography: Cryptography;
  let referMixer: ReferMixer;
  let moneyMixer: MoneyMixer;
  let account1: MemberAccount;
  let account2: MemberAccount;
  let account3: MemberAccount;
  let account4: MemberAccount;
  let ac1params: AccountParams;
  let ac2params: AccountParams;
  let ac3params: AccountParams;
  let ac4params: AccountParams;
  let user1: Signer;
  let user2: Signer;
  let user3: Signer;
  // For refer test
  let referAlpha: BigNumber;
  let referBeta: BigNumber;
  let originalMessage: BigNumber;
  let referPuNonce: BigNumber;
  let referPrNonce: BigNumber;
  before(async () => {
    params = await setupProtocol();
    await setUpInitialMemberAndStart(params);
    cryptography = params.cryptography;
    protocol = params.protocol;
    referMixer = params.referMixer;
    moneyMixer = params.moneyMixer;
    account1 = params.account1;
    account2 = params.account2;
    account3 = params.account3;
    ac1params = params.ac1params;
    ac2params = params.ac2params;
    ac3params = params.ac3params;
    user1 = params.user1;
    user2 = params.user2;
    user3 = params.user3;
    // Set up
    referPrNonce = getRandomBigNumber(params.q);
    referPuNonce = modPower(params.g, referPrNonce, params.p);
    referAlpha = getRandomBigNumber(params.q);
    referBeta = getRandomBigNumber(params.q);
    // Deploy account4
    ac4params = generateMemberAccountParams(params.g, params.q, params.p);
    account4 = await deployMemberAccount(
      params.protocol.address,
      params.cryptography.address,
      ac4params.pusign,
      ac4params.pusk,
      ac4params.purk,
      ac4params.punonce,
      params.user4,
    );
  });
  describe('Test ReferWorkflow', () => {
    it('startRequestRefer', async () => {
      // Let user3 try to refer user4
      // Generate message
      const encoded = ethers.utils.defaultAbiCoder.encode(['address', 'uint256'], [account3.address, referPuNonce]);
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const {r: rSig1, s: sSig1} = await generateElgamaSignature(cryptography, actualMessage, ac1params.prrk, p, q);
      await account1.connect(user1).startRequestRefer(account3.address, referPuNonce, rSig1, sSig1);
      expect(await referMixer.referIdentify(account3.address, referPuNonce)).to.be.eq(true);
    });
    it('sendReferRequest', async () => {
      const message = await cryptography.blindSchnorrMessage(
        referPuNonce,
        referAlpha,
        referBeta,
        ac1params.pusign,
        account4.address,
      );
      originalMessage = message.e0;
      // Generate message
      const encoded = ethers.utils.defaultAbiCoder.encode(['uint256', 'uint256'], [referPuNonce, message.e]);
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac3params.prrk, p, q);
      await account3.connect(user3).sendReferRequest(referPuNonce, message.e, rSig, sSig);
      const getE = await referMixer.referMessage(referPuNonce);
      expect(getE.eq(message.e)).to.be.eq(true);
    });
    it('signReferRequest', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + referPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startSignPhaseForReferMixer();
      const e = await referMixer.referMessage(referPuNonce);
      const s = await cryptography.signBlindSchnorrMessage(ac1params.prsign, referPrNonce, e);
      // Start sign
      const encoded = ethers.utils.defaultAbiCoder.encode(['uint256', 'uint256'], [referPuNonce, s]);
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac1params.prrk, p, q);
      await account1.connect(user1).signReferRequest(referPuNonce, s, rSig, sSig);
      const referSig = await referMixer.referSignature(referPuNonce);
      expect(referSig.eq(s)).to.be.eq(true);
    });
    it('onBoardMember', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + referPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startOnboardPhaseForReferMixer();

      const referSig = await referMixer.referSignature(referPuNonce);
      const unblindSig = await cryptography.unblindBlindSchnorrMessage(referSig, referAlpha, originalMessage);
      // Start sign
      const encoded = ethers.utils.defaultAbiCoder.encode(['uint256', 'uint256'], [unblindSig.e0, unblindSig.s0]);
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac4params.prrk, p, q);

      await account4
        .connect(params.user4)
        .onBoard(unblindSig.e0, unblindSig.s0, rSig, sSig, {value: protocolFee.add(joinFee)});
      expect(await protocol.members(account4.address)).to.be.eq(true);
    });
  });
});
