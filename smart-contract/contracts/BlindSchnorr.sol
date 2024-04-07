// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";

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
    BlindSchnoor bs,
    uint256 calldata r,
    uint256 calldata alpha,
    uint256 calldata beta,
    address calldata m
) internal view returns (BlindSchnorrSig) {
    uint256 r0 = Math.mulmod(
        r,
        Math.mulmod(
            Math.inverse(Math.modexp(bs.g, alpha, bs.p), bs.p),
            Math.inverse(Math.modexp(y, beta, bs.p), bs.p),
            bs.p
        )
    );
    uint256 e0 = Math.mod(keccak256(abi.encode(m, r0)), bs.q);
    return BlindSchnorrSig(e0, Math.mod(e0 + beta, bs.q));
}

function signMessage(
    BlindSchnoor bs,
    uint256 calldata prk,
    uint256 calldata K,
    uint256 calldata e
) internal view returns (uint256) {
    return Math.mod(K + prk * e, bs.q);
}

function unblindMessage(
    BlindSchnoor bs,
    BlindSig calldata s,
    uint256 calldata alpha,
    BlindSig calldata sig
) public view returns (SchnorrSignature) {
    return SchnorrSignature(Math.mod(s - alpha, bs.q), sig.e0);
}

function verifySchnorrSignature(
    BlindSchnoor bs,
    Signature calldata sig,
    address calldata m,
    uint256 calldata pk
) public returns (bool) {
    uint256 verifyFactor = mulmod(
        Math.modexp(bs.g, sig.s0, bs.q),
        Math.modexp(pk, sig.e0, bs.q),
        bs.q
    );
    require(
        Math.mod(sig.e0, bs.q) ==
            Math.mode(keccak256(abi.encode(m, verifyFactor)), bs.q)
    );
}
