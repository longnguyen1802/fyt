// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./math/Math.sol";

struct Elgama {
    uint256 p;
    uint256 g;
}

/**
 *
 * @param m Message sign
 * @param r Part of signature
 * @param s Part of signature
 * @param y Public key of signre
 */
function verifyElgamaSignature(
    Elgama storage elgama,
    uint256 m,
    uint256 r,
    uint256 s,
    uint256 y
) view {
    uint256 computeVerify = mulmod(
        Math.modExp(r, s, elgama.p),
        Math.modExp(y, r, elgama.p),
        elgama.p
    );

    uint256 hashMessage = uint256(keccak256(abi.encode(m)));
    require(Math.modExp(elgama.g, hashMessage, elgama.p) == computeVerify);
}
