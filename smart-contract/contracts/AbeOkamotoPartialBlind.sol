// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";

contract AbeOkamotoBlind {
    uint256 public p;
    uint256 public q;
    uint256 public g;
    uint256 public d;

    function prepareMessage(
        uint256 calldata u,
        uint256 calldata s,
        uint256 calldata d,
        uint256 calldata info
    ) internal view returns (uint256, uint256) {
        uint256 z = keccak256(info);
        uint256 a = Math.expmod(g, u, p);
        uint256 b = Math.mulmod(Math.expmod(g, s, p), Math.expmod(z, d, p), p);
        return (a, b);
    }

    function blindMessage(
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
            Math.mulmod(Math.expmod(g, t1, p), Math.expmod(y, t2, p), p),
            p
        );
        uint256 beta = Math.mulmod(
            b,
            Math.mulmod(Math.expmod(g, t3, p), Math.expmod(z, t4, p), p),
            p
        );
        uint256 theta = keccak256(abi.encode(alpha, beta, z, m));
        return Math.mod(theta - t2 - t4, q);
    }

    function signMessage(
        uint256 calldata u,
        uint256 calldata s,
        uint256 calldata e,
        uint256 calldata x
    ) internal view returns (uint256, uint256, uint256, uint256) {
        uint256 c = Math.mod(e - d, q);
        uint256 r = Math.mod(u - Math.mulmod(c, x, q), q);
        return (r, c, s, d);
    }

    function unblindMessage(
        uint256 calldata t1,
        uint256 calldata t2,
        uint256 calldata t3,
        uint256 calldata t4,
        uint256 calldata r,
        uint256 calldata c,
        uint256 calldata s,
        uint256 calldata d
    ) internal view returns (uint256, uint256, uint256, uint256) {
        uint256 rho = Math.mod(r + t1, q);
        uint256 omega = Math.mod(c + t2, q);
        uint256 sigma = Math.mod(s + t3, q);
        uint256 delta = Math.mod(d + t4, q);
        return (rho, omega, sigma, delta);
    }

    function verifySignature(
        uint256 calldata y,
        uint256 calldata z,
        uint256 m,
        uint256 calldata rho,
        uint256 calldata omega,
        uint256 calldata sigma,
        uint256 calldata delta
    ) internal view returns (bool) {
        uint256 checkAlpha = Math.mulmod(
            Math.expmod(g, rho, p),
            Math.expmod(y, omega, p),
            p
        );
        uint256 checkBeta = Math.mulmod(
            Math.expmod(g, sigma, p),
            Math.expmod(z, delta, p),
            p
        );
        uint245 checkSig = keccak256(abi.encode(checkAlpha, checkBeta, z, m));
        require(Math.mod(omega + delta, q) == Math.mod(checkSig, q));
    }
}
