// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";

struct AbeOkamotoBlind {
    uint256 p;
    uint256 q;
    uint256 g;
    uint256 d;
}

function prepareMessage(
    AbeOkamotoBlind ab,
    uint256 calldata u,
    uint256 calldata s,
    uint256 calldata d,
    uint256 calldata info
) internal view returns (uint256, uint256) {
    uint256 z = keccak256(info);
    uint256 a = Math.expmod(ab.g, u, ab.p);
    uint256 b = Math.mulmod(
        Math.expmod(ab.g, s, ab.p),
        Math.expmod(z, ab.d, ab.p),
        ab.p
    );
    return (a, b);
}

function blindMessage(
    AbeOkamotoBlind ab,
    uint256 calldata a,
    uint256 calldata b,
    uint256 calldata t1,
    uint256 calldata t2,
    uint256 calldata t3,
    uint256 calldata t4,
    uint256 calldata m,
    uint256 calldata z,
    uint256 calldata y
) internal view returns (uint256) {
    uint256 alpha = Math.mulmod(
        a,
        Math.mulmod(
            Math.expmod(ab.g, t1, ab.p),
            Math.expmod(y, t2, ab.p),
            ab.p
        ),
        ab.p
    );
    uint256 beta = Math.mulmod(
        b,
        Math.mulmod(
            Math.expmod(ab.g, t3, ab.p),
            Math.expmod(z, t4, ab.p),
            ab.p
        ),
        ab.p
    );
    uint256 theta = keccak256(abi.encode(alpha, beta, z, m));
    return Math.mod(theta - t2 - t4, ab.q);
}

function signMessage(
    AbeOkamotoBlind ab,
    uint256 calldata u,
    uint256 calldata s,
    uint256 calldata e,
    uint256 calldata x
) internal view returns (uint256, uint256, uint256, uint256) {
    uint256 c = Math.mod(e - ab.d, ab.q);
    uint256 r = Math.mod(u - Math.mulmod(c, x, ab.q), ab.q);
    return (r, c, s, ab.d);
}

function unblindMessage(
    AbeOkamotoBlind ab,
    uint256 calldata t1,
    uint256 calldata t2,
    uint256 calldata t3,
    uint256 calldata t4,
    uint256 calldata r,
    uint256 calldata c,
    uint256 calldata s,
    uint256 calldata d
) internal view returns (uint256, uint256, uint256, uint256) {
    uint256 rho = Math.mod(r + t1, ab.q);
    uint256 omega = Math.mod(c + t2, ab.q);
    uint256 sigma = Math.mod(s + t3, ab.q);
    uint256 delta = Math.mod(ab.d + t4, ab.q);
    return (rho, omega, sigma, delta);
}

function verifyAbeOkamotoSignature(
    AbeOkamotoBlind ab,
    uint256 calldata y,
    uint256 calldata z,
    address m,
    uint256 calldata rho,
    uint256 calldata omega,
    uint256 calldata sigma,
    uint256 calldata delta
) internal view returns (bool) {
    uint256 checkAlpha = Math.mulmod(
        Math.expmod(ab.g, rho, ab.p),
        Math.expmod(y, omega, ab.p),
        ab.p
    );
    uint256 checkBeta = Math.mulmod(
        Math.expmod(ab.g, sigma, ab.p),
        Math.expmod(z, delta, ab.p),
        ab.p
    );
    uint245 checkSig = keccak256(abi.encode(checkAlpha, checkBeta, z, m));
    require(Math.mod(omega + delta, ab.q) == Math.mod(checkSig, ab.q));
}
