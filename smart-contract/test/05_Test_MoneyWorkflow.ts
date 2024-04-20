import {expect} from 'chai';
import {ethers} from 'hardhat';
import {BigNumber, Signer} from 'ethers';
import {Cryptography, MemberAccount, Protocol, ReferMixer, MoneyMixer} from '../typechain-types';
import {ProtocolParams, setupProtocol, setUpInitialMemberAndStart, AccountParams} from './helpers/setup';
import {getRandomBigNumber, getRandomRelativePrime, modPower} from './utils/Math';
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

describe('MoneyWorkflow', () => {
  // Protocol params
  let params: ProtocolParams;

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
  let user4: Signer;
  // For refer
  let referAlpha: BigNumber;
  let referBeta: BigNumber;
  let originalMessage: BigNumber;
  let referPuNonce: BigNumber;
  let referPrNonce: BigNumber;
  //  For money test
  let t1: BigNumber;
  let t2: BigNumber;
  let t3: BigNumber;
  let t4: BigNumber;
  let info: BigNumber;
  let z: BigNumber;
  let e: BigNumber;
  let r: BigNumber;
  let c: BigNumber;
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
    user4 = params.user4;
    // Set up
    referPrNonce = getRandomBigNumber(params.q);
    referPuNonce = modPower(params.g, referPrNonce, params.p);
    referAlpha = getRandomBigNumber(params.q);
    referBeta = getRandomBigNumber(params.q);
    t1 = getRandomBigNumber(q);
    t2 = getRandomBigNumber(q);
    t3 = getRandomBigNumber(q);
    t4 = getRandomBigNumber(q);
    info = joinFee;
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
    // Let make account 3 refer account 4 first
  });
  describe('Test MoneyWorkflow', () => {
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

    it('endRound', async () => {
      await account1.connect(user1).bidSigner({value: signerDepositFee});
      let targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startSignPhaseForMoneyMixer();
      targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startReceivePhaseForMoneyMixer();
      targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startValidityCheckPhaseForMoneyMixer();
      targetBlockNumber = (await getCurrentBlockNumber()) + roundLong;
      await advanceBlockTo(targetBlockNumber);
      await protocol.endRound();
      await protocol.startNewRound();
    });
    it('sendTransaction', async () => {
      // Send from account4 to account3
      let [a, b, _z] = await cryptography.prepareAbeOkamotoMessage(ac1params.prnonce, info);
      let index = BigNumber.from(1);
      z = _z;
      e = await cryptography.blindAbeOkamotoMessage(a, b, t1, t2, t3, t4, z, account3.address, ac1params.pusign);
      // Start sign
      const encoded = ethers.utils.defaultAbiCoder.encode(['uint256', 'uint256'], [index, e]);
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac4params.prsk, p, q);
      await account4.connect(user4).sendTransaction(index, e, rSig, sSig);
      let getIndex = await moneyMixer.distributeMoneyMessage(account4.address, e);
      expect(getIndex.eq(index)).to.be.eq(true);
    });
    it('signTransaction', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startSignPhaseForMoneyMixer();

      let [_r, _c] = await cryptography.signAbeOkamotoMessage(ac1params.prnonce, e, ac1params.prsign);
      r = _r;
      c = _c;
      // Start sign
      const encoded = ethers.utils.defaultAbiCoder.encode(['address', 'uint256', 'uint256'], [account4.address, e, r]);
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac1params.prrk, p, q);
      await account1.connect(user1).signTransaction(account4.address, e, r, rSig, sSig);
      let getSig = await moneyMixer.distributeMoneySignature(account4.address, e);
      expect(getSig.eq(r)).to.be.eq(true);
    });
    it('receiveTransaction', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startReceivePhaseForMoneyMixer();

      let [rho, omega, sigma, delta] = await cryptography.unblindAbeOkamotoMessage(t1, t2, t3, t4, r, c);
      // Start sign
      const encoded = ethers.utils.defaultAbiCoder.encode(
        ['uint256', 'uint256', 'uint256', 'uint256'],
        [rho, delta, omega, sigma],
      );
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac3params.prrk, p, q);
      await account3.connect(user3).receiveTransaction(info, rho, delta, omega, sigma, rSig, sSig);
      let moneyRev = await moneyMixer.receiveTransactionConfirm(account3.address);
      expect(moneyRev.eq(info.div(2))).to.be.eq(true);
    });
    it('validityCheck', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startValidityCheckPhaseForMoneyMixer();
      await protocol.connect(user1).validityCheck();
    });
  });
});
