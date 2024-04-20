import {expect} from 'chai';
import {ethers} from 'hardhat';
import {BigNumber} from 'ethers';
import {Cryptography} from '../typechain-types';
import {getRandomRelativePrime, getRandomBigNumber, modPower} from './utils/Math';
import {generateKeyPair} from './utils/KeyGen';
import {p, q, g} from './utils/Constant';
describe('Cryptography', () => {
  let Cryptography;
  let cryptography: Cryptography;
  let Ms: BigNumber;
  let Md: BigNumber;
  let accounts: any;

  before(async () => {
    [, ...accounts] = await ethers.getSigners();
    Cryptography = await ethers.getContractFactory('Cryptography');
    Ms = getRandomBigNumber(q);
    Md = getRandomBigNumber(q);
    cryptography = await Cryptography.deploy(p, q, g, Ms, Md);
  });

  describe('BlindSchnorr', () => {
    it('verifySchnoorSignature', async () => {
      const K: BigNumber = getRandomBigNumber(q);
      const r: BigNumber = modPower(g, K, p);
      const alpha: BigNumber = getRandomBigNumber(q);
      const beta: BigNumber = getRandomBigNumber(q);
      const m: string = accounts[0].address;
      const {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);
      const {e0, e} = await cryptography.blindSchnorrMessage(r, alpha, beta, puSignKey, m);

      const s: BigNumber = await cryptography.signBlindSchnorrMessage(prSignKey, K, e);

      const signature = await cryptography.unblindBlindSchnorrMessage(s, alpha, e0);
      expect(await cryptography.verifySchnorrSignature(signature, m, puSignKey)).to.be.equal(true);
    });
  });

  describe('AbeOkamoto Partial Blind', () => {
    it('verifyAbeOkamotoSignature', async () => {
      const prnonce: BigNumber = getRandomBigNumber(q);

      const {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);

      const info: BigNumber = BigNumber.from(100);
      const [a, b, z] = await cryptography.prepareAbeOkamotoMessage(prnonce, info);
      const t1: BigNumber = getRandomBigNumber(q);
      const t2: BigNumber = getRandomBigNumber(q);
      const t3: BigNumber = getRandomBigNumber(q);
      const t4: BigNumber = getRandomBigNumber(q);
      const m: string = accounts[0].address;

      const e: BigNumber = await cryptography.blindAbeOkamotoMessage(a, b, t1, t2, t3, t4, z, m, puSignKey);

      const [r, c]: BigNumber[] = await cryptography.signAbeOkamotoMessage(prnonce, e, prSignKey);

      const [rho, omega, sigma, delta] = await cryptography.unblindAbeOkamotoMessage(t1, t2, t3, t4, r, c);

      expect(await cryptography.verifyAbeOkamotoSignature(puSignKey, z, m, rho, omega, sigma, delta)).to.be.equal(
        true,
      );
    });
  });

  describe('Elgama', () => {
    it('verifyElgamaSignature', async () => {
      const {pubKey: puSignKey, privKey: prSignKey} = generateKeyPair(g, q, p);

      const k: BigNumber = getRandomRelativePrime(q, p.sub(1));
      const m: BigNumber = getRandomBigNumber(q);

      const [r, s]: BigNumber[] = await cryptography.generateElgamaSignature(k, m, prSignKey);
      expect(await cryptography.verifyElgamaSignature(m, r, s, puSignKey)).to.be.eq(true);
    });
  });
});
