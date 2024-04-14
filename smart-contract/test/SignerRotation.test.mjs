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

  const { pubKey: punonce, priKey: prnonce } = generateKeyPair(g, q, p);

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
  await _protocol.setUpMixer(_referMixer.address, _moneyMixer.address);
  return { _cryptography, _protocol, _referMixer, _moneyMixer };
}

describe("SignerRotation", () => {
  // Constant just for testing
  const protocolFee = BigNumber.from(100);
  const joinFee = BigNumber.from(100000);
  const signerDepositFee = BigNumber.from(100000);
  const deploymenLength = 7 * 700; // 7000 block a day
  const roundLong = 1200;

  let p;
  let q;
  let g;
  let user0;
  let user1;
  let user2;
  let user3;
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

  //  Protocol contract
  let protocol;
  before(async () => {
    p = BigNumber.from(
      "115792089237316195423570985008687907852837564279074904382605163141518161494337",
    );
    q = BigNumber.from("341948486974166000522343609283189");
    g = BigNumber.from(
      "3382179820063921351711459720945002840687054300606715993250688069077934439078",
    );
    [user0, user1, user2, user3] = await ethers.getSigners();
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
      ac1params.pusign,
      ac1params.pusk,
      ac1params.purk,
      ac1params.punonce,
      user2,
    );

    ac3params = generateMemberAccountParams(g, q, p);
    account3 = await deployMemberAccount(
      protocol.address,
      cryptography.address,
      ac1params.pusign,
      ac1params.pusk,
      ac1params.purk,
      ac1params.punonce,
      user3,
    );
  });
});
