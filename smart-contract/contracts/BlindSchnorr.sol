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

contract BlindSchnoor {
    uint256 public g;
    uint256 public p;
    uint256 public q;
    function blindMessage(
        uint256 calldata r,
        uint256 calldata alpha,
        uint256 calldata beta,
        uint256 calldata m
    ) internal view returns (BlindSchnorrSig) {
        uint256 r0 = Math.mulmod(
            r,
            Math.mulmod(
                Math.inverse(Math.modexp(g, alpha, p), p),
                Math.inverse(Math.modexp(y, beta, p), p),
                p
            )
        );
        uint256 e0 = Math.mod(keccak256(abi.encode(m, r0)), q);
        return BlindSchnorrSig(e0, Math.mod(e0 + beta, q));
    }

    function signMessage(
        uint256 calldata prk,
        uint256 calldata K,
        uint256 calldata e
    ) internal view returns (uint256) {
        return Math.mod(K + prk * e, q);
    }

    function unblindMessage(
        BlindSig calldata s,
        uint256 calldata alpha,
        BlindSig calldata sig
    ) public view returns (SchnorrSignature) {
        return SchnorrSignature(Math.mod(s - alpha, q), sig.e0);
    }

    function verifySignature(
        Signature calldata sig,
        uint256 calldata m,
        uint256 calldata pk
    ) public returns (bool) {
        uint256 verifyFactor = mulmod(
            Math.modexp(g, sig.s0, q),
            Math.modexp(pk, sig.e0, q),
            q
        );
        require(
            Math.mod(sig.e0, q) ==
                Math.mode(keccak256(abi.encode(m, verifyFactor)), q)
        );
    }
}
