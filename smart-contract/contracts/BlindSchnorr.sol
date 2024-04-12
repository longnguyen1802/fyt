// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./math/Math.sol";

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

function blindMessage(
    BlindSchnoor calldata bs,
    uint256 r,
    uint256 alpha,
    uint256 beta,
    uint256 y,
    address m
) view returns (SchnorrSignature memory) {
    uint256 r0 = mulmod(
        r,
        mulmod(
            Math.invMod(Math.modExp(bs.g, alpha, bs.p), bs.p),
            Math.invMod(Math.modExp(y, bs.p - 1 - beta, bs.p), bs.p),
            bs.p
        ),
        bs.p
    );
    y % r;
    uint256 e0 = uint256(keccak256(abi.encode(m, r0))) % bs.q;
    return SchnorrSignature(e0, e0 + (beta % bs.q));
}

function signMessage(
    BlindSchnoor calldata bs,
    uint256 prk,
    uint256 K,
    uint256 e
) pure returns (uint256) {
    return K + ((prk * e) % bs.q);
}

function unblindMessage(
    BlindSchnoor calldata bs,
    uint256 s,
    uint256 alpha,
    uint256 e0
) pure returns (SchnorrSignature memory) {
    return SchnorrSignature((s - alpha) % bs.q, e0);
}

function verifySchnorrSignature(
    BlindSchnoor storage bs,
    SchnorrSignature memory sig,
    address m,
    uint256 pk
) view {
    uint256 verifyFactor = mulmod(
        Math.modExp(bs.g, sig.s0, bs.q),
        Math.modExp(pk, sig.e0, bs.q),
        bs.q
    );
    require(
        (sig.e0 % bs.q) ==
            uint256(keccak256(abi.encode(m, verifyFactor))) % bs.q
    );
}
