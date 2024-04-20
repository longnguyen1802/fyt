import {expect} from 'chai';
import {ethers} from 'hardhat';
import {Cryptography} from '../typechain-types';
import {getRandomRelativePrime, getRandomBigInt, modPower} from './utils/Math';
import {generateKeyPair} from './utils/KeyGen';
import {p, q, g} from './utils/Constant';

describe('Cryptography', () => {
  let Cryptography: any; // Changed the type to any
  let cryptography: Cryptography;
  let Ms: bigint;
  let Md: bigint;
  let accounts: any;

  before(async () => {
    [, ...accounts] = await ethers.getSigners();
    Cryptography = await ethers.getContractFactory('Cryptography');
    Ms = getRandomBigInt(q);
    Md = getRandomBigInt(q);
    cryptography = await Cryptography.deploy(p, q, g, Ms, Md);
  });

  describe('BlindSchnorr', () => {
    it('verifySchnoorSignature', async () => {
      const K: bigint = getRandomBigInt(q);
      const r: bigint = modPower(g, K, p);
      const alpha: bigint = getRandomBigInt(q);
      const beta: bigint = getRandomBigInt(q);
      const m: string = accounts[0].address;
      const {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);
      const [e0, e] = await cryptography.blindSchnorrMessage(r, alpha, beta, puSignKey, m);
      const s: bigint = await cryptography.signBlindSchnorrMessage(prSignKey, K, e);

      const [_, s0] = await cryptography.unblindBlindSchnorrMessage(s, alpha, e0);
      expect(await cryptography.verifySchnorrSignature(e0, s0, m, puSignKey)).to.be.equal(true);
    });
  });

  describe('AbeOkamoto Partial Blind', () => {
    it('verifyAbeOkamotoSignature', async () => {
      const prnonce: bigint = getRandomBigInt(q);

      const {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);

      const info: bigint = BigInt(100);
      const [a, b, z] = await cryptography.prepareAbeOkamotoMessage(prnonce, info);
      const t1: bigint = getRandomBigInt(q);
      const t2: bigint = getRandomBigInt(q);
      const t3: bigint = getRandomBigInt(q);
      const t4: bigint = getRandomBigInt(q);
      const m: string = accounts[0].address;

      const e: bigint = await cryptography.blindAbeOkamotoMessage(a, b, t1, t2, t3, t4, z, m, puSignKey);

      const [r, c]: bigint[] = await cryptography.signAbeOkamotoMessage(prnonce, e, prSignKey);

      const [rho, omega, sigma, delta] = await cryptography.unblindAbeOkamotoMessage(t1, t2, t3, t4, r, c);

      expect(await cryptography.verifyAbeOkamotoSignature(puSignKey, z, m, rho, omega, sigma, delta)).to.be.equal(
        true,
      );
    });
  });

  describe('Elgama', () => {
    it('verifyElgamaSignature', async () => {
      const {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);

      const k: bigint = getRandomRelativePrime(q, p - 1n);
      const m: bigint = getRandomBigInt(q);

      const [r, s]: bigint[] = await cryptography.generateElgamaSignature(k, m, prSignKey);
      expect(await cryptography.verifyElgamaSignature(m, r, s, puSignKey)).to.be.eq(true);
    });
  });
});
