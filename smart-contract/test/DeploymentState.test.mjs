import { expect } from 'chai';
import pkg from 'hardhat';
const { ethers } = pkg;
const { BigNumber, utils } = ethers;

async function deployCryptography() {
    Cryptography = await ethers.getContractFactory('Cryptography');
    p = BigNumber.from('115792089237316195423570985008687907852837564279074904382605163141518161494337');
    q = BigNumber.from('341948486974166000522343609283189');
    g = BigNumber.from('3382179820063921351711459720945002840687054300606715993250688069077934439078');
    Ms = getRandomBigNumber(q);
    Md = getRandomBigNumber(q);
    cryptography = await Cryptography.deploy(p, q, g, Ms,Md);
    return cryptography;
}

async function deployProtocol() {
    Protocol = await ethers.getContractFactory('Protocol');
    numeParentFee = BigNumber.from(1);
    demoParentFee = BigNumber.from(2);
    protocolFee = BigNumber.from(100);
    joinFee = BigNumber.from(100000);
    signerDepositFee = BigNumber.from(100000);
    deploymenLength = 7*7000; // 7000 block a day
    roundLong = 12000;
    protocol = await Protocol.deploy(numeParentFee,demoParentFee,protocolFee,joinFee,signerDepositFee,deploymenLength,roundLong);
    return protocol;
}

async function deployReferMixer(protocolAddress,cryptographyAddress) {
    ReferMixer = await ethers.getContractFactory('ReferMixer');
    phaseLength = 4000;
    referMixer = await ReferMixer.deploy(protocolAddress,cryptographyAddress,phaseLength);
    return referMixer;
}

async function deployMoneyMixer(protocolAddress,cryptographyAddress) {
    MoneyMixer = await ethers.getContractFactory('MoneyMixer');
    phaseLength = 3000;
    moneyMixer = await MoneyMixer.deploy(protocolAddress,cryptographyAddress,phaseLength);
    return moneyMixer;
}

async function setUpMixer(protocol,referMixerAddress,moneyMixerAddress) {
    protocol.setUpMixer(moneyMixerAddress,referMixerAddress);
}

async function deployMemberAccount(protocolAddress,cryptographyAddress,pubKey,sendKey,receiveKey,signNonce) {
    MemberAccount = await ethers.getContractFactory('MemberAccount');
    signerDepositFee = BigNumber.from(100000);
    account = await MemberAccount.deploy(protocolAddress,cryptographyAddress,pubKey,sendKey,receiveKey,signNonce,signerDepositFee);
}
describe("Deployment", () => {
    
    // Cryptography contract
    let cryptography;

    // Mixer contract
    let referMixer;
    let moneyMixer;

    // Member Account contract
    // We will need 3 account to test
    // account0: Signer
    let account0,account1,account2;

    //  Protocol contract
    let protocol;
    before(async () => {
        [user0, user1, user2] = await ethers.getSigners();
    })

})