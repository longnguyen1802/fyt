import { expect } from 'chai';
import pkg from 'hardhat';
const { ethers } = pkg;
const { BigNumber, utils } = ethers;

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
    let temp = bBN;
    bBN = aBN.mod(bBN);
    aBN = temp;
  }

  return aBN;
}

function getRandomRelativePrime(max,moduloNumber) {
  let number = getRandomBigNumber(max);
  let subMod = moduloNumber.mod(number);
  while(!gcd(number,subMod).eq(1)){
    number = getRandomBigNumber(max);
    subMod = moduloNumber.mod(number);
  }
  return number;
}

function getRandomBigNumber(max) {
  return ethers.BigNumber.from(ethers.utils.randomBytes(32)).mod(max);
}

function generateKeyPair(g,q,p) {
  let privKey = getRandomBigNumber(q);
  let pubKey = modPower(g,privKey,p);
  return {pubKey,privKey}
} 

describe('Cryptography', () => {
  let Cryptography, cryptography, p, q, g, d,Ms,Md,accounts;

  before(async () => {
    [, ...accounts] = await ethers.getSigners();
    Cryptography = await ethers.getContractFactory('Cryptography');
    p = BigNumber.from('115792089237316195423570985008687907852837564279074904382605163141518161494337');
    q = BigNumber.from('341948486974166000522343609283189');
    g = BigNumber.from('3382179820063921351711459720945002840687054300606715993250688069077934439078');
    Ms = getRandomBigNumber(q);
    Md = getRandomBigNumber(q);
    cryptography = await Cryptography.deploy(p, q, g, Ms,Md);
  });

  describe('BlindSchnorr', () => {
    it('verifySchnoorSignature', async () => {
      const K = getRandomBigNumber(q)
      const r = modPower(g,K,p);

      const alpha = getRandomBigNumber(q);
      const beta = getRandomBigNumber(q);
      const m = accounts[0].address;
      let {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);
      let {e0,e} =  await cryptography.blindSchnorrMessage(r, alpha, beta, puSignKey, m);
      
      let s = await cryptography.signBlindSchnorrMessage(prSignKey,K,e);

      let signature = await cryptography.unblindBlindSchnorrMessage(s,alpha,e0);

      expect(await cryptography.verifySchnorrSignature(signature, m, puSignKey)).to.be.equal(true);
    });
  });

  describe('AbeOkamoto Partial Blind', () => {
    it('verifyAbeOkamotoSignature', async () => {
      const prnonce = getRandomBigNumber(q);
      
      let {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);

      const info = BigNumber.from(100);
      const [a,b,z] =  await cryptography.prepareAbeOkamotoMessage(prnonce,info);
      const t1 = getRandomBigNumber(q);
      const t2 = getRandomBigNumber(q);
      const t3 = getRandomBigNumber(q);
      const t4 = getRandomBigNumber(q);
      const m = accounts[0].address;

      const e = await cryptography.blindAbeOkamotoMessage(a,b,t1,t2,t3,t4,z,m,puSignKey)

      const [r,c] = await cryptography.signAbeOkamotoMessage(prnonce,e,prSignKey)

      const [rho,omega,sigma,delta] = await cryptography.unblindAbeOkamotoMessage(t1,t2,t3,t4,r,c)

      expect(await cryptography.verifyAbeOkamotoSignature(puSignKey,z,m,rho,omega,sigma,delta)).to.be.equal(true);
    });
  });

  describe('Elgama', () => {
    it('verifyElgamaSignature', async () => {
      let {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);

      let k = getRandomRelativePrime(q,p.sub(1));
      const m = getRandomBigNumber(q);

      const [r,s] = await cryptography.generateElgamaSignature(k,m,prSignKey);
      expect(await cryptography.verifyElgamaSignature(m,r,s,puSignKey)).to.be(true);
    });
  });
});
