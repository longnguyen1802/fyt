import {expect} from 'chai';
import {ethers} from 'hardhat';
import {Signer} from 'ethers';
import {Cryptography, MemberAccount, Protocol, ReferMixer, MoneyMixer} from '../typechain-types';
import {ProtocolParams, setupProtocol, setUpInitialMemberAndStart, AccountParams} from './helpers/setup';
import {getRandomBigInt, getRandomRelativePrime, modPower} from './utils/Math';
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
  let referAlpha: bigint;
  let referBeta: bigint;
  let e0: bigint;
  let referPuNonce: bigint;
  let referPrNonce: bigint;
  //  For money test
  let t1: bigint;
  let t2: bigint;
  let t3: bigint;
  let t4: bigint;
  let info: bigint;
  let z: bigint;
  let e: bigint;
  let r: bigint;
  let c: bigint;
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
    referPrNonce = getRandomBigInt(params.q);
    referPuNonce = modPower(params.g, referPrNonce, params.p);
    referAlpha = getRandomBigInt(params.q);
    referBeta = getRandomBigInt(params.q);
    t1 = getRandomBigInt(q);
    t2 = getRandomBigInt(q);
    t3 = getRandomBigInt(q);
    t4 = getRandomBigInt(q);
    info = joinFee;
    // Deploy account4
    ac4params = generateMemberAccountParams(params.g, params.q, params.p);
    account4 = await deployMemberAccount(
      await params.protocol.getAddress(),
      await params.cryptography.getAddress(),
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
      const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
        ['address', 'uint256'],
        [await account3.getAddress(), referPuNonce],
      );
      const hashMes = ethers.keccak256(encoded);
      const actualMessage = BigInt(hashMes);
      const {r: rSig1, s: sSig1} = await generateElgamaSignature(cryptography, actualMessage, ac1params.prrk, p, q);
      await account1.connect(user1).startRequestRefer(await account3.getAddress(), referPuNonce, rSig1, sSig1);
      expect(await referMixer.referIdentify(await account3.getAddress(), referPuNonce)).to.be.eq(true);
    });
    it('sendReferRequest', async () => {
      const [_e0, e] = await cryptography.blindSchnorrMessage(
        referPuNonce,
        referAlpha,
        referBeta,
        ac1params.pusign,
        await account4.getAddress(),
      );
      e0 = _e0;
      // Generate message
      const encoded = ethers.AbiCoder.defaultAbiCoder().encode(['uint256', 'uint256'], [referPuNonce, e]);
      const hashMes = ethers.keccak256(encoded);
      const actualMessage = BigInt(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac3params.prrk, p, q);
      await account3.connect(user3).sendReferRequest(referPuNonce, e, rSig, sSig);
      const getE = await referMixer.referMessage(referPuNonce);
      expect(getE === e).to.be.eq(true);
    });
    it('signReferRequest', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + referPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startSignPhaseForReferMixer();
      const e = await referMixer.referMessage(referPuNonce);
      const s = await cryptography.signBlindSchnorrMessage(ac1params.prsign, referPrNonce, e);
      // Start sign
      const encoded = ethers.AbiCoder.defaultAbiCoder().encode(['uint256', 'uint256'], [referPuNonce, s]);
      const hashMes = ethers.keccak256(encoded);
      const actualMessage = BigInt(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac1params.prrk, p, q);
      await account1.connect(user1).signReferRequest(referPuNonce, s, rSig, sSig);
      const referSig = await referMixer.referSignature(referPuNonce);
      expect(referSig === s).to.be.eq(true);
    });
    it('onBoardMember', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + referPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startOnboardPhaseForReferMixer();
      const referSig = await referMixer.referSignature(referPuNonce);
      const [_, s0] = await cryptography.unblindBlindSchnorrMessage(referSig, referAlpha, e0);
      // Start sign
      const encoded = ethers.AbiCoder.defaultAbiCoder().encode(['uint256', 'uint256'], [e0, s0]);
      const hashMes = ethers.keccak256(encoded);
      const actualMessage = BigInt(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac4params.prrk, p, q);

      await account4.connect(params.user4).onBoard(e0, s0, rSig, sSig, {value: protocolFee + joinFee});
      expect(await protocol.members(await account4.getAddress())).to.be.eq(true);
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
      let index = BigInt(1);
      z = _z;
      e = await cryptography.blindAbeOkamotoMessage(a, b, t1, t2, t3, t4, z, account3.getAddress(), ac1params.pusign);
      // Start sign
      const encoded = ethers.AbiCoder.defaultAbiCoder().encode(['uint256', 'uint256'], [index, e]);
      const hashMes = ethers.keccak256(encoded);
      const actualMessage = BigInt(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac4params.prsk, p, q);
      await account4.connect(user4).sendTransaction(index, e, rSig, sSig);
      let getIndex = await moneyMixer.distributeMoneyMessage(account4.getAddress(), e);
      expect(getIndex === index).to.be.eq(true);
    });
    it('signTransaction', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startSignPhaseForMoneyMixer();

      let [_r, _c] = await cryptography.signAbeOkamotoMessage(ac1params.prnonce, e, ac1params.prsign);
      r = _r;
      c = _c;
      // Start sign
      const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
        ['address', 'uint256', 'uint256'],
        [await account4.getAddress(), e, r],
      );
      const hashMes = ethers.keccak256(encoded);
      const actualMessage = BigInt(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac1params.prrk, p, q);
      await account1.connect(user1).signTransaction(account4.getAddress(), e, r, rSig, sSig);
      let getSig = await moneyMixer.distributeMoneySignature(account4.getAddress(), e);
      expect(getSig === r).to.be.eq(true);
    });
    it('receiveTransaction', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startReceivePhaseForMoneyMixer();

      let [rho, omega, sigma, delta] = await cryptography.unblindAbeOkamotoMessage(t1, t2, t3, t4, r, c);
      // Start sign
      const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
        ['uint256', 'uint256', 'uint256', 'uint256'],
        [rho, delta, omega, sigma],
      );
      const hashMes = ethers.keccak256(encoded);
      const actualMessage = BigInt(hashMes);
      const {r: rSig, s: sSig} = await generateElgamaSignature(cryptography, actualMessage, ac3params.prrk, p, q);
      await account3.connect(user3).receiveTransaction(info, rho, delta, omega, sigma, rSig, sSig);
      let moneyRev = await moneyMixer.receiveTransactionConfirm(account3.getAddress());
      expect(moneyRev === info / BigInt(2)).to.be.eq(true);
    });
    it('validityCheck', async () => {
      let targetBlockNumber = (await getCurrentBlockNumber()) + moneyPhaseLength;
      await advanceBlockTo(targetBlockNumber);
      await protocol.startValidityCheckPhaseForMoneyMixer();
      await protocol.connect(user1).validityCheck();
    });
  });
});
