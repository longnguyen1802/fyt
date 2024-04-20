// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct AbeOkamotoBlind {
  uint256 p;
  uint256 q;
  uint256 g;
  uint256 mS;
  uint256 mD;
}
struct BlindSchnorrSig {
  // Original Signature
  uint256 e0;
  // Blind Signature
  uint256 e;
}

struct SchnorrSignature {
  uint256 e0;
  uint256 s0;
}

struct BlindSchnoor {
  uint256 g;
  uint256 p;
  uint256 q;
}

struct Elgama {
  uint256 p;
  uint256 g;
}

struct ElgamaSignature {
  uint256 r;
  uint256 s;
}

interface ICryptography {
  /**************************Blind Schnoor Function ***************************/
  function blindSchnorrMessage(
    uint256 r,
    uint256 alpha,
    uint256 beta,
    uint256 y,
    address m
  ) external view returns (BlindSchnorrSig memory);

  function signBlindSchnorrMessage(
    uint256 prk,
    uint256 K,
    uint256 e
  ) external view returns (uint256);

  function unblindBlindSchnorrMessage(
    uint256 s,
    uint256 alpha,
    uint256 e0
  ) external view returns (SchnorrSignature memory);

  function verifySchnorrSignature(
    SchnorrSignature memory sig,
    address m,
    uint256 pk
  ) external returns (bool);

  /**************************Abe Okamoto Function ***************************/
  function prepareAbeOkamotoMessage(
    uint256 u,
    uint256 info
  ) external view returns (uint256, uint256, uint256);

  function blindAbeOkamotoMessage(
    uint256 a,
    uint256 b,
    uint256 t1,
    uint256 t2,
    uint256 t3,
    uint256 t4,
    uint256 z,
    address m,
    uint256 y
  ) external view returns (uint256);

  function signAbeOkamotoMessage(
    uint256 u,
    uint256 e,
    uint256 x
  ) external view returns (uint256, uint256);

  function unblindAbeOkamotoMessage(
    uint256 t1,
    uint256 t2,
    uint256 t3,
    uint256 t4,
    uint256 r,
    uint256 c
  ) external view returns (uint256, uint256, uint256, uint256);

  function verifyAbeOkamotoSignature(
    uint256 y,
    uint256 z,
    address m,
    uint256 rho,
    uint256 omega,
    uint256 sigma,
    uint256 delta
  ) external returns (bool);

  /************************** Elgama ***************************/
  function verifyElgamaSignature(
    uint256 m,
    uint256 r,
    uint256 s,
    uint256 y
  ) external view returns (bool);
}
