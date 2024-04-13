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

describe('BlindSchnorr', () => {
  let bs;

  beforeEach(() => {
    // Initialize the BlindSchnoor struct
    bs = {
      g: BigNumber.from("3382179820063921351711459720945002840687054300606715993250688069077934439078"),
      p: BigNumber.from("115792089237316195423570985008687907852837564279074904382605163141518161494337"),
      q: BigNumber.from("341948486974166000522343609283189"),
    };
  });

  it('should verify a Schnorr signature', () => {
    
  });
});

// describe("BlindSchnorr", function () {
//   const p = BigInt('115792089237316195423570985008687907852837564279074904382605163141518161494337');
//   const q = BigInt('341948486974166000522343609283189');
//   const g = BigInt('3382179820063921351711459720945002840687054300606715993250688069077934439078');

//   it("should blindMessage correctly", async function () {
//     const r = 123;
//     const alpha = 456;
//     const beta = 789;
//     const y = 1234;
//     const m = "0x1234567890abcdef";

//     const blindSchnorr = {
//       e0: 0,
//       e: 0,
//       p: p.toString(),
//       q: q.toString(),
//       g: g.toString(),
//     };

//     const sig = await blindMessage(blindSchnorr, r, alpha, beta, y, m);

//     expect(sig.e0).to.be.not.equal(0);
//     expect(sig.e).to.be.not.equal(0);
//   });

//   it("should signMessage correctly", async function () {
//     const prk = 789;
//     const K = 456;
//     const e = 123;

//     const blindSchnorr = {
//       e0: 0,
//       e: 0,
//       p: p.toString(),
//       q: q.toString(),
//       g: g.toString(),
//     };

//     const sig = await signMessage(blindSchnorr, prk, K, e);

//     expect(sig).to.be.not.equal(0);
//   });

//   it("should unblindMessage correctly", async function () {
//     const s = 456;
//     const alpha = 789;
//     const e0 = 123;

//     const blindSchnorr = {
//       e0: 0,
//       e: 0,
//       p: p.toString(),
//       q: q.toString(),
//       g: g.toString(),
//     };

//     const sig = await unblindMessage(blindSchnorr, s, alpha, e0);

//     expect(sig.s0).to.be.not.equal(0);
//     expect(sig.e0).to.be.equal(e0);
//   });

//   async function blindMessage(blindSchnorr, r, alpha, beta, y, m) {
//     // Implement the blindMessage logic here
//     const e0 = utils.keccak256(utils.toUtf8Bytes(m)).toString();
//     const e = (BigInt(e0) * BigInt(alpha)) % BigInt(blindSchnorr.q);

//     return {
//       e0: e0,
//       e: e.toString(),
//     };
//   }

//   async function signMessage(blindSchnorr, prk, K, e) {
//     // Implement the signMessage logic here
//     const s = (BigInt(K) + BigInt(prk) * BigInt(e)) % BigInt(blindSchnorr.q);
//     return s.toString();
//   }

//   async function unblindMessage(blindSchnorr, s, alpha, e0) {
//     // Implement the unblindMessage logic here
//     const s0 = (BigInt(s) - BigInt(alpha) * BigInt(e0)) % BigInt(blindSchnorr.q);
//     return {
//       s0: s0.toString(),
//       e0: e0,
//     };
//   }
// });