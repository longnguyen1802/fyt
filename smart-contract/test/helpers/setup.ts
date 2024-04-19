import { BigNumber, Signer } from "ethers";
import { Cryptography, MemberAccount, MoneyMixer, Protocol, ReferMixer } from "../../typechain-types";
import { deployAll, deployMemberAccount, generateMemberAccountParams } from "./deploy";
import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
export type AccountParams = {
    pusign: BigNumber;
    prsign: BigNumber;
    purk: BigNumber;
    prrk: BigNumber;
    pusk: BigNumber;
    prsk: BigNumber;
    punonce: BigNumber;
    prnonce: BigNumber;
};

export type ProtocolParams = {
    p: BigNumber;
    q: BigNumber;
    g: BigNumber;
    user0: Signer;
    user1: Signer;
    user2: Signer;
    user3: Signer;
    user4: Signer;
    cryptography: Cryptography;
    protocol: Protocol;
    referMixer: ReferMixer;
    moneyMixer: MoneyMixer;
    account0: MemberAccount;
    ac1params: AccountParams;
    account1: MemberAccount;
    ac2params: AccountParams;
    account2: MemberAccount;
    ac3params: AccountParams;
    account3: MemberAccount;
  };
  
  export async function setupProtocol(): Promise<ProtocolParams> {
    const params: ProtocolParams = {} as ProtocolParams;
  
    // Set up parameters
    params.p = BigNumber.from(
      "115792089237316195423570985008687907852837564279074904382605163141518161494337",
    );
    params.q = BigNumber.from("341948486974166000522343609283189");
    params.g = BigNumber.from(
      "3382179820063921351711459720945002840687054300606715993250688069077934439078",
    );
  
    // Set up signers
    [params.user0, params.user1, params.user2, params.user3,params.user4] = await ethers.getSigners();
  
    // Deploy contracts
    const { _cryptography, _protocol, _referMixer, _moneyMixer } = await deployAll();
    params.cryptography = _cryptography;
    params.protocol = _protocol;
    params.referMixer = _referMixer;
    params.moneyMixer = _moneyMixer;
  
    // Generate member account parameters
    params.ac1params = generateMemberAccountParams(params.g, params.q, params.p);
    params.ac2params = generateMemberAccountParams(params.g, params.q, params.p);
    params.ac3params = generateMemberAccountParams(params.g, params.q, params.p);
  
    // Deploy member accounts
    params.account1 = await deployMemberAccount(
      params.protocol.address,
      params.cryptography.address,
      params.ac1params.pusign,
      params.ac1params.pusk,
      params.ac1params.purk,
      params.ac1params.punonce,
      params.user1,
    );
    params.account2 = await deployMemberAccount(
      params.protocol.address,
      params.cryptography.address,
      params.ac2params.pusign,
      params.ac2params.pusk,
      params.ac2params.purk,
      params.ac2params.punonce,
      params.user2,
    );
    params.account3 = await deployMemberAccount(
        params.protocol.address,
        params.cryptography.address,
        params.ac3params.pusign,
        params.ac3params.pusk,
        params.ac3params.purk,
        params.ac3params.punonce,
        params.user3,
    );
    return params;
}
export async function setUpInitialMemberAndStart(params:ProtocolParams){
    const protocolFee: BigNumber = BigNumber.from(100);
    const deploymenLength: number = 7 * 700; // 7000 block a day
    let currentBlockNumber:number = await ethers.provider.getBlockNumber();
    // Register initial members
    await params.account1.connect(params.user1).registerInitialMember(protocolFee, { value: protocolFee });
    await params.account2.connect(params.user2).registerInitialMember(protocolFee, { value: protocolFee });
    await params.account3.connect(params.user3).registerInitialMember(protocolFee, { value: protocolFee });

    // Advance blocks to simulate deployment completion
    currentBlockNumber = await ethers.provider.getBlockNumber();
    await time.advanceBlockTo(currentBlockNumber + deploymenLength);
    await params.protocol.closeDeploymentState();
    await params.protocol.startNewRound();
}