import { ethers } from "hardhat";
import {BigNumber,Signer} from "ethers"
import { getRandomBigNumber } from "../utils/Math";
import { generateKeyPair } from "../utils/KeyGen";
import { Cryptography,Protocol,MemberAccount,ReferMixer,MoneyMixer } from "../../typechain-types";

export function generateMemberAccountParams(g: BigNumber, q: BigNumber, p: BigNumber): { pusign: BigNumber, prsign: BigNumber, purk: BigNumber, prrk: BigNumber, pusk: BigNumber, prsk: BigNumber, punonce: BigNumber, prnonce: BigNumber } {
    const { pubKey: pusign, privKey: prsign } = generateKeyPair(g, q, p);
    const { pubKey: purk, privKey: prrk } = generateKeyPair(g, q, p);
    const { pubKey: pusk, privKey: prsk } = generateKeyPair(g, q, p);
    const { pubKey: punonce, privKey: prnonce } = generateKeyPair(g, q, p);
    return { pusign, prsign, purk, prrk, pusk, prsk, punonce, prnonce };
  }
  
  async function deployCryptography(): Promise<Cryptography> {
    const Cryptography = await ethers.getContractFactory("Cryptography");
    const p: BigNumber = BigNumber.from(
      "115792089237316195423570985008687907852837564279074904382605163141518161494337",
    );
    const q: BigNumber = BigNumber.from("341948486974166000522343609283189");
    const g: BigNumber = BigNumber.from(
      "3382179820063921351711459720945002840687054300606715993250688069077934439078",
    );
    const Ms: BigNumber = getRandomBigNumber(q);
    const Md: BigNumber = getRandomBigNumber(q);
    const cryptography: Cryptography = await Cryptography.deploy(p, q, g, Ms, Md);
    await cryptography.deployed();
    return cryptography;
  }
  
  async function deployProtocol(): Promise<Protocol> {
    const Protocol = await ethers.getContractFactory("Protocol");
    const numeParentFee: BigNumber = BigNumber.from(1);
    const demoParentFee: BigNumber = BigNumber.from(2);
    const protocolFee: BigNumber = BigNumber.from(100);
    const joinFee: BigNumber = BigNumber.from(100000);
    const signerDepositFee: BigNumber = BigNumber.from(100000);
    const deploymenLength: number = 7 * 700; // 700 block a day
    const roundLong: number = 1200;
    const protocol: Protocol = await Protocol.deploy(
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
  
  async function deployReferMixer(protocolAddress: string, cryptographyAddress: string): Promise<ReferMixer> {
    const ReferMixer = await ethers.getContractFactory("ReferMixer");
    const phaseLength: number = 400;
    const referMixer: ReferMixer = await ReferMixer.deploy(
      protocolAddress,
      cryptographyAddress,
      phaseLength,
    );
    await referMixer.deployed();
    return referMixer;
  }
  
  async function deployMoneyMixer(protocolAddress: string, cryptographyAddress: string): Promise<MoneyMixer> {
    const MoneyMixer = await ethers.getContractFactory("MoneyMixer");
    const phaseLength: number = 300;
    const moneyMixer: MoneyMixer = await MoneyMixer.deploy(
      protocolAddress,
      cryptographyAddress,
      phaseLength,
    );
    await moneyMixer.deployed();
    return moneyMixer;
  }
  
  export async function deployMemberAccount(
    protocolAddress: string,
    cryptographyAddress: string,
    pubKey: BigNumber,
    sendKey: BigNumber,
    receiveKey: BigNumber,
    signNonce: BigNumber,
    user: Signer
  ): Promise<MemberAccount> {
    const MemberAccount = await ethers.getContractFactory("MemberAccount");
    const signerDepositFee: BigNumber = BigNumber.from(100000);
    const protocolFee: BigNumber = BigNumber.from(100);
    const joinFee: BigNumber = BigNumber.from(100000);
    const account: MemberAccount = await MemberAccount.connect(user).deploy(
      protocolAddress,
      cryptographyAddress,
      pubKey,
      sendKey,
      receiveKey,
      signNonce,
      signerDepositFee,
      protocolFee,
      joinFee
    );
    await account.deployed();
    return account;
  }
  
export async function deployAll(): Promise<{ _cryptography: Cryptography, _protocol: Protocol, _referMixer: ReferMixer, _moneyMixer: MoneyMixer }> {
    const _cryptography: Cryptography = await deployCryptography();
    const _protocol: Protocol = await deployProtocol();
    const _referMixer: ReferMixer = await deployReferMixer(
      _protocol.address,
      _cryptography.address,
    );
    const _moneyMixer: MoneyMixer = await deployMoneyMixer(
      _protocol.address,
      _cryptography.address,
    );
    await _protocol.setUpMixer( _moneyMixer.address,_referMixer.address,);
    return { _cryptography, _protocol, _referMixer, _moneyMixer };
  }