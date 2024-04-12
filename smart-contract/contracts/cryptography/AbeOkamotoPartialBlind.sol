// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../math/Math.sol";

struct AbeOkamotoBlind {
    uint256 p;
    uint256 q;
    uint256 g;
    uint256 d;
}

function prepareMessage(
    AbeOkamotoBlind calldata ab,
    uint256 u,
    uint256 s,
    uint256 info
) view returns (uint256, uint256) {
    uint256 z = uint256(keccak256(abi.encode(info)));
    uint256 a = Math.modExp(ab.g, u, ab.p);
    uint256 b = mulmod(
        Math.modExp(ab.g, s, ab.p),
        Math.modExp(z, ab.d, ab.p),
        ab.p
    );
    return (a, b);
}

function blindMessage(
    AbeOkamotoBlind calldata ab,
    uint256 a,
    uint256 b,
    uint256 t1,
    uint256 t2,
    uint256 t3,
    uint256 t4,
    uint256 m,
    uint256 z,
    uint256 y
) view returns (uint256) {
    uint256 alpha = mulmod(
        a,
        mulmod(Math.modExp(ab.g, t1, ab.p), Math.modExp(y, t2, ab.p), ab.p),
        ab.p
    );
    uint256 beta = mulmod(
        b,
        mulmod(Math.modExp(ab.g, t3, ab.p), Math.modExp(z, t4, ab.p), ab.p),
        ab.p
    );
    uint256 theta = uint256(keccak256(abi.encode(alpha, beta, z, m)));
    return theta - t2 - (t4 % ab.q);
}

function signMessage(
    AbeOkamotoBlind calldata ab,
    uint256 u,
    uint256 s,
    uint256 e,
    uint256 x
) pure returns (uint256, uint256, uint256, uint256) {
    uint256 c = e - (ab.d % ab.q);
    uint256 r = u - (mulmod(c, x, ab.q) % ab.q);
    return (r, c, s, ab.d);
}

function unblindMessage(
    AbeOkamotoBlind calldata ab,
    uint256 t1,
    uint256 t2,
    uint256 t3,
    uint256 t4,
    uint256 r,
    uint256 c,
    uint256 s
) pure returns (uint256, uint256, uint256, uint256) {
    uint256 rho = (r + (t1 % ab.q));
    uint256 omega = (c + (t2 % ab.q));
    uint256 sigma = (s + (t3 % ab.q));
    uint256 delta = (ab.d + (t4 % ab.q));
    return (rho, omega, sigma, delta);
}

function verifyAbeOkamotoSignature(
    AbeOkamotoBlind storage ab,
    uint256 y,
    uint256 z,
    address m,
    uint256 rho,
    uint256 omega,
    uint256 sigma,
    uint256 delta
) view {
    uint256 checkAlpha = mulmod(
        Math.modExp(ab.g, rho, ab.p),
        Math.modExp(y, omega, ab.p),
        ab.p
    );
    uint256 checkBeta = mulmod(
        Math.modExp(ab.g, sigma, ab.p),
        Math.modExp(z, delta, ab.p),
        ab.p
    );
    uint256 checkSig = uint256(
        keccak256(abi.encode(checkAlpha, checkBeta, z, m))
    );
    require((omega + (delta % ab.q)) == (checkSig % ab.q));
}
