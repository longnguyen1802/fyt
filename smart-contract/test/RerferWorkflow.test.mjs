import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import pkg from "hardhat";

const { ethers } = pkg;
const { BigNumber } = ethers;

function modPower(base, exponent, modulus) {
  let result = BigNumber.from(1);
  base = base.mod(modulus);
  while (exponent.gt(0)) {
    if (exponent.mod(2).eq(1)) {
      result = result.mul(base).mod(modulus);
    }
    exponent = exponent.div(2);
    base = base.mul(base).mod(modulus);
  }
  return result;
}

function gcd(a, b) {
  // Convert the inputs to BigNumber
  let aBN = BigNumber.from(a.toString());
  let bBN = BigNumber.from(b.toString());

  // Implement the Euclidean algorithm to find the GCD
  while (!bBN.isZero()) {
    const temp = bBN;
    bBN = aBN.mod(bBN);
    aBN = temp;
  }

  return aBN;
}

function getRandomRelativePrime(max, moduloNumber) {
  let number = getRandomBigNumber(max);
  let subMod = moduloNumber.mod(number);
  while (!gcd(number, subMod).eq(1)) {
    number = getRandomBigNumber(max);
    subMod = moduloNumber.mod(number);
  }
  return number;
}

function getRandomBigNumber(max) {
  return ethers.BigNumber.from(ethers.utils.randomBytes(32)).mod(max);
}

function generateKeyPair(g, q, p) {
  const privKey = getRandomBigNumber(q);
  const pubKey = modPower(g, privKey, p);
  return { pubKey, privKey };
}

function generateMemberAccountParams(g, q, p) {
  const { pubKey: pusign, privKey: prsign } = generateKeyPair(g, q, p);

  const { pubKey: purk, privKey: prrk } = generateKeyPair(g, q, p);

  const { pubKey: pusk, privKey: prsk } = generateKeyPair(g, q, p);

  const { pubKey: punonce, privKey: prnonce } = generateKeyPair(g, q, p);

  return {
    pusign,
    prsign,
    purk,
    prrk,
    pusk,
    prsk,
    punonce,
    prnonce,
  };
}

async function deployCryptography() {
  const Cryptography = await ethers.getContractFactory("Cryptography");
  const p = BigNumber.from(
    "115792089237316195423570985008687907852837564279074904382605163141518161494337",
  );
  const q = BigNumber.from("341948486974166000522343609283189");
  const g = BigNumber.from(
    "3382179820063921351711459720945002840687054300606715993250688069077934439078",
  );
  const Ms = getRandomBigNumber(q);
  const Md = getRandomBigNumber(q);
  const cryptography = await Cryptography.deploy(p, q, g, Ms, Md);
  await cryptography.deployed();
  return cryptography;
}

async function deployProtocol() {
  const Protocol = await ethers.getContractFactory("Protocol");
  const numeParentFee = BigNumber.from(1);
  const demoParentFee = BigNumber.from(2);
  const protocolFee = BigNumber.from(100);
  const joinFee = BigNumber.from(100000);
  const signerDepositFee = BigNumber.from(100000);
  const deploymenLength = 7 * 700; // 700 block a day
  const roundLong = 1200;
  const protocol = await Protocol.deploy(
    numeParentFee,
    demoParentFee,
    protocolFee,
    joinFee,
    signerDepositFee,
    deploymenLength,
    roundLong,
  );
  await protocol.deployed();
  return protocol;
}

async function deployReferMixer(protocolAddress, cryptographyAddress) {
  const ReferMixer = await ethers.getContractFactory("ReferMixer");
  const phaseLength = 400;
  const referMixer = await ReferMixer.deploy(
    protocolAddress,
    cryptographyAddress,
    phaseLength,
  );
  await referMixer.deployed();
  return referMixer;
}

async function deployMoneyMixer(protocolAddress, cryptographyAddress) {
  const MoneyMixer = await ethers.getContractFactory("MoneyMixer");
  const phaseLength = 300;
  const moneyMixer = await MoneyMixer.deploy(
    protocolAddress,
    cryptographyAddress,
    phaseLength,
  );
  await moneyMixer.deployed();
  return moneyMixer;
}

async function deployMemberAccount(
  protocolAddress,
  cryptographyAddress,
  pubKey,
  sendKey,
  receiveKey,
  signNonce,
  user,
) {
  const MemberAccount = await ethers.getContractFactory("MemberAccount");
  const signerDepositFee = BigNumber.from(100000);
  const account = await MemberAccount.connect(user).deploy(
    protocolAddress,
    cryptographyAddress,
    pubKey,
    sendKey,
    receiveKey,
    signNonce,
    signerDepositFee,
  );
  await account.deployed();
  return account;
}

async function deployAll() {
  const _cryptography = await deployCryptography();
  const _protocol = await deployProtocol();
  const _referMixer = await deployReferMixer(
    _protocol.address,
    _cryptography.address,
  );
  const _moneyMixer = await deployMoneyMixer(
    _protocol.address,
    _cryptography.address,
  );
  await _protocol.setUpMixer(_moneyMixer.address, _referMixer.address);
  return { _cryptography, _protocol, _referMixer, _moneyMixer };
}

describe("ReferWorkflow", () => {
  // Constant just for testing
  const protocolFee = BigNumber.from(100);
  const joinFee = BigNumber.from(100000);
  const signerDepositFee = BigNumber.from(100000);
  const deploymenLength = 7 * 700; // 7000 block a day
  const roundLong = 1200;
  // Phase control
  const referPhaseLong = 400;
  const moneyPhaseLong = 300;

  let p;
  let q;
  let g;
  let user0;
  let user1;
  let user2;
  let user3;
  let user4;
  // Cryptography contract
  let cryptography;

  // Mixer contract
  let referMixer;
  let moneyMixer;

  // Member Account contract
  // We will need 3 account to test
  // account0: Signer
  let account0;
  let ac1params;
  let account1;
  let ac2params;
  let account2;
  let ac3params;
  let account3;
  let ac4params;
  let account4;

  //  Protocol contract
  let protocol;
  let referAlpha;
  let referBeta;
  let originalMessage;
  let referPuNonce;
  let referPrNonce;
  before(async () => {
    p = BigNumber.from(
      "115792089237316195423570985008687907852837564279074904382605163141518161494337",
    );
    q = BigNumber.from("341948486974166000522343609283189");
    g = BigNumber.from(
      "3382179820063921351711459720945002840687054300606715993250688069077934439078",
    );

    referPrNonce = getRandomBigNumber(q);
    referPuNonce = modPower(g, referPrNonce, p);

    referAlpha = getRandomBigNumber(q);
    referBeta = getRandomBigNumber(q);

    [user0, user1, user2, user3, user4] = await ethers.getSigners();
    const { _cryptography, _protocol, _referMixer, _moneyMixer } =
      await deployAll();
    cryptography = _cryptography;
    protocol = _protocol;
    referMixer = _referMixer;
    moneyMixer = _moneyMixer;

    ac1params = generateMemberAccountParams(g, q, p);
    account1 = await deployMemberAccount(
      protocol.address,
      cryptography.address,
      ac1params.pusign,
      ac1params.pusk,
      ac1params.purk,
      ac1params.punonce,
      user1,
    );

    ac2params = generateMemberAccountParams(g, q, p);
    account2 = await deployMemberAccount(
      protocol.address,
      cryptography.address,
      ac2params.pusign,
      ac2params.pusk,
      ac2params.purk,
      ac2params.punonce,
      user2,
    );

    ac3params = generateMemberAccountParams(g, q, p);
    account3 = await deployMemberAccount(
      protocol.address,
      cryptography.address,
      ac3params.pusign,
      ac3params.pusk,
      ac3params.purk,
      ac3params.punonce,
      user3,
    );
    ac4params = generateMemberAccountParams(g, q, p);
    account4 = await deployMemberAccount(
      protocol.address,
      cryptography.address,
      ac4params.pusign,
      ac4params.pusk,
      ac4params.purk,
      ac4params.punonce,
      user4,
    );

    await account1
      .connect(user1)
      .registerInitialMember(protocolFee, { value: protocolFee });
    expect(await protocol.members(account1.address)).to.be.eq(true);
    let currentBlockNumber = await ethers.provider.getBlockNumber();
    await time.advanceBlockTo(currentBlockNumber + 20);
    await account2
      .connect(user2)
      .registerInitialMember(protocolFee, { value: protocolFee });
    currentBlockNumber = await ethers.provider.getBlockNumber();
    await time.advanceBlockTo(currentBlockNumber + 20);
    await account3
      .connect(user3)
      .registerInitialMember(protocolFee, { value: protocolFee });
    currentBlockNumber = await ethers.provider.getBlockNumber();
    await time.advanceBlockTo(currentBlockNumber + deploymenLength);
    await protocol.closeDeploymentState();
    await protocol.startNewRound();
  });
  describe("Test ReferWorkflow", () => {
    it("startRequestRefer", async () => {
      // Let user3 try to refer user4
      // Generate message
      const encoded = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint256"],
        [account3.address, referPuNonce],
      );
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const { r: rSig1, s: sSig1 } = await generateElgamaSignature(
        cryptography,
        actualMessage,
        ac1params.prrk,
        p,
        q,
      );
      await account1
        .connect(user1)
        .startRequestRefer(account3.address, referPuNonce, rSig1, sSig1);
      expect(
        await referMixer.referIdentify(account3.address, referPuNonce),
      ).to.be.eq(true);
    });
    it("sendReferRequest", async () => {
      const message = await cryptography.blindSchnorrMessage(
        referPuNonce,
        referAlpha,
        referBeta,
        ac1params.pusign,
        account4.address,
      );
      originalMessage = message.e0;
      // Generate message
      const encoded = ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256"],
        [referPuNonce, message.e],
      );
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const { r: rSig, s: sSig } = await generateElgamaSignature(
        cryptography,
        actualMessage,
        ac3params.prrk,
        p,
        q,
      );
      await account3
        .connect(user3)
        .sendReferRequest(referPuNonce, message.e, rSig, sSig);
      const getE = await referMixer.referMessage(referPuNonce);
      expect(getE.eq(message.e)).to.be.eq(true);
    });
    it("signReferRequest", async () => {
      const currentBlockNumber = await ethers.provider.getBlockNumber();
      await time.advanceBlockTo(currentBlockNumber + referPhaseLong);
      await protocol.startSignPhaseForReferMixer();
      const e = await referMixer.referMessage(referPuNonce);
      const s = await cryptography.signBlindSchnorrMessage(
        ac1params.prsign,
        referPrNonce,
        e,
      );
      // Start sign
      const encoded = ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256"],
        [referPuNonce, s],
      );
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const { r: rSig, s: sSig } = await generateElgamaSignature(
        cryptography,
        actualMessage,
        ac1params.prrk,
        p,
        q,
      );
      await account1
        .connect(user1)
        .signReferRequest(referPuNonce, s, rSig, sSig);
      const referSig = await referMixer.referSignature(referPuNonce);
      expect(referSig.eq(s)).to.be.eq(true);
    });
    it("onBoardMember", async () => {
      const currentBlockNumber = await ethers.provider.getBlockNumber();
      await time.advanceBlockTo(currentBlockNumber + referPhaseLong);
      await protocol.startOnboardPhaseForReferMixer();

      const referSig = await referMixer.referSignature(referPuNonce);
      const unblindSig = await cryptography.unblindBlindSchnorrMessage(
        referSig,
        referAlpha,
        originalMessage,
      );
      // Start sign
      const encoded = ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256"],
        [unblindSig.e0, unblindSig.s0],
      );
      const hashMes = ethers.utils.keccak256(encoded);
      const actualMessage = BigNumber.from(hashMes);
      const { r: rSig, s: sSig } = await generateElgamaSignature(
        cryptography,
        actualMessage,
        ac4params.prrk,
        p,
        q,
      );

      await account4
        .connect(user4)
        .onBoard(unblindSig.e0, unblindSig.s0, rSig, sSig);
      expect(await protocol.members(account4.address)).to.be.eq(true);
    });
  });
});
