// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "../math/Math.sol";
import "../interfaces/ICryptography.sol";
import "hardhat/console.sol";
contract Cryptography is ICryptography {
  uint256 immutable p;
  uint256 immutable q;
  uint256 immutable g;
  BlindSchnoor bs;
  AbeOkamotoBlind ab;
  Elgama elgama;

  constructor(uint256 _p, uint256 _q, uint256 _g, uint256 _d, uint256 _s) {
    p = _p;
    q = _q;
    g = _g;
    bs = BlindSchnoor(g, p, q);
    ab = AbeOkamotoBlind(p, q, g, _d, _s);
    elgama = Elgama(p, g);
  }

  /**************************Blind Schnoor Function ***************************/
  function blindSchnorrMessage(
    uint256 r,
    uint256 alpha,
    uint256 beta,
    uint256 pusign,
    address memberAddress
  ) public view returns (uint256, uint256) {
    uint256 r0 = mulmod(
      r,
      mulmod(
        Math.invMod(Math.modExp(bs.g, alpha, bs.p), bs.p),
        Math.invMod(Math.modExp(pusign, beta, bs.p), bs.p),
        bs.p
      ),
      bs.p
    );
    uint256 e0 = uint256(keccak256(abi.encode(memberAddress, r0))) % bs.p;
    uint256 e = (e0 + beta) % bs.p;
    return (e0, e);
  }

  function signBlindSchnorrMessage(
    uint256 prsign,
    uint256 K,
    uint256 e
  ) public view returns (uint256) {
    return (K + bs.q - mulmod(prsign, e, bs.q)) % bs.q;
  }

  function unblindBlindSchnorrMessage(
    uint256 s,
    uint256 alpha,
    uint256 e0
  ) public view returns (uint256, uint256) {
    uint256 s0 = (s + bs.q - alpha) % bs.q;
    return (e0, s0);
  }

  function verifySchnorrSignature(
    uint256 e0,
    uint256 s0,
    address m,
    uint256 pusign
  ) external view returns (bool) {
    uint256 verifyFactor = mulmod(
      Math.modExp(bs.g, s0, bs.p),
      Math.modExp(pusign, e0, bs.p),
      bs.p
    );
    return ((e0 % bs.p) == uint256(keccak256(abi.encode(m, verifyFactor))) % bs.p);
  }
  /**************************Abe Okamoto Function ***************************/
  function prepareAbeOkamotoMessage(
    uint256 prnonce,
    uint256 info
  ) public view returns (uint256, uint256, uint256) {
    uint256 z = uint256(keccak256(abi.encode(info)));
    uint256 a = Math.modExp(ab.g, prnonce, ab.p);
    uint256 b = mulmod(Math.modExp(ab.g, ab.mS, ab.p), Math.modExp(z, ab.mD, ab.p), ab.p);
    return (a, b, z);
  }

  function blindAbeOkamotoMessage(
    uint256 a,
    uint256 b,
    uint256 t1,
    uint256 t2,
    uint256 t3,
    uint256 t4,
    uint256 z,
    address m,
    uint256 pusign
  ) public view returns (uint256) {
    uint256 alpha = mulmod(
      a,
      mulmod(Math.modExp(ab.g, t1, ab.p), Math.modExp(pusign, t2, ab.p), ab.p),
      ab.p
    );
    uint256 beta = mulmod(
      b,
      mulmod(Math.modExp(ab.g, t3, ab.p), Math.modExp(z, t4, ab.p), ab.p),
      ab.p
    );
    uint256 theta = uint256(keccak256(abi.encode(alpha, beta, z, m)));
    return (theta + ab.q - ((t2 + t4) % ab.q)) % ab.q;
  }

  function signAbeOkamotoMessage(
    uint256 prnonce,
    uint256 e,
    uint256 prsign
  ) public view returns (uint256, uint256) {
    uint256 c = (e + ab.q - (ab.mD % ab.q)) % ab.q;
    uint256 r = (prnonce + ab.q - (mulmod(c, prsign, ab.q) % ab.q)) % ab.q;
    return (r, c);
  }

  function unblindAbeOkamotoMessage(
    uint256 t1,
    uint256 t2,
    uint256 t3,
    uint256 t4,
    uint256 r,
    uint256 c
  ) public view returns (uint256, uint256, uint256, uint256) {
    uint256 rho = (r + (t1 % ab.q));
    uint256 omega = (c + (t2 % ab.q));
    uint256 sigma = (ab.mS + (t3 % ab.q));
    uint256 delta = (ab.mD + (t4 % ab.q));
    return (rho, omega, sigma, delta);
  }

  function verifyAbeOkamotoSignature(
    uint256 pusign,
    uint256 z,
    address m,
    uint256 rho,
    uint256 omega,
    uint256 sigma,
    uint256 delta
  ) public view returns (bool) {
    uint256 checkAlpha = mulmod(
      Math.modExp(ab.g, rho, ab.p),
      Math.modExp(pusign, omega, ab.p),
      ab.p
    );
    uint256 checkBeta = mulmod(Math.modExp(ab.g, sigma, ab.p), Math.modExp(z, delta, ab.p), ab.p);

    uint256 checkSig = uint256(keccak256(abi.encode(checkAlpha, checkBeta, z, m)));
    return ((omega + delta) % ab.q) == (checkSig % ab.q);
  }

  /************************** Elgama ***************************/
  function generateElgamaSignature(
    uint256 k,
    uint256 m,
    uint256 prkey
  ) public view returns (uint256, uint256) {
    uint256 r = Math.modExp(g, k, p);
    uint256 hashMessage = uint256(keccak256(abi.encode(m)));
    uint256 part = mulmod(prkey, r, p - 1) % (p - 1);
    uint256 s;
    if (hashMessage > part) {
      s = mulmod((hashMessage - part) % (p - 1), Math.invMod(k, p - 1), p - 1);
    } else {
      s = mulmod((p - 1 - part + hashMessage) % (p - 1), Math.invMod(k, p - 1), p - 1);
    }

    return (r, s);
  }
  /**
   *
   * @param m Message sign
   * @param r Part of signature
   * @param s Part of signature
   * @param pukey Public key of signer
   */
  function verifyElgamaSignature(
    uint256 m,
    uint256 r,
    uint256 s,
    uint256 pukey
  ) public view returns (bool) {
    uint256 computeVerify = mulmod(
      Math.modExp(r, s, elgama.p),
      Math.modExp(pukey, r, elgama.p),
      elgama.p
    );

    uint256 hashMessage = uint256(keccak256(abi.encode(m)));
    return (Math.modExp(elgama.g, hashMessage, elgama.p) == computeVerify);
  }
}
