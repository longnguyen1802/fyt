// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "../math/Math.sol";
import "../interfaces/ICryptography.sol";

contract Cryptography is ICryptography {
    uint256 immutable p;
    uint256 immutable q;
    uint256 immutable g;
    BlindSchnoor bs;
    AbeOkamotoBlind ab;
    Elgama elgama;

    constructor(uint256 _p, uint256 _q, uint256 _g, uint256 _d) {
        p = _p;
        q = _q;
        g = _g;
        bs = BlindSchnoor(g, p, q);
        ab = AbeOkamotoBlind(p, q, g, _d);
        elgama = Elgama(p, g);
    }

    /**************************Blind Schnoor Function ***************************/
    function blindSchnorrMessage(
        uint256 r,
        uint256 alpha,
        uint256 beta,
        uint256 y,
        address m
    ) public view returns (SchnorrSignature memory) {
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

    function signBlindSchnorrMessage(
        uint256 prk,
        uint256 K,
        uint256 e
    ) public view returns (uint256) {
        return K + ((prk * e) % bs.q);
    }

    function unblindBlindSchnorrMessage(
        uint256 s,
        uint256 alpha,
        uint256 e0
    ) public view returns (SchnorrSignature memory) {
        return SchnorrSignature((s - alpha) % bs.q, e0);
    }

    function verifySchnorrSignature(
        SchnorrSignature memory sig,
        address m,
        uint256 pk
    ) public view {
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
    /**************************Abe Okamoto Function ***************************/
    function prepareAbeOkamotoMessage(
        uint256 u,
        uint256 s,
        uint256 info
    ) public view returns (uint256, uint256) {
        uint256 z = uint256(keccak256(abi.encode(info)));
        uint256 a = Math.modExp(ab.g, u, ab.p);
        uint256 b = mulmod(
            Math.modExp(ab.g, s, ab.p),
            Math.modExp(z, ab.d, ab.p),
            ab.p
        );
        return (a, b);
    }

    function blindAbeOkamotoMessage(
        uint256 a,
        uint256 b,
        uint256 t1,
        uint256 t2,
        uint256 t3,
        uint256 t4,
        uint256 m,
        uint256 z,
        uint256 y
    ) public view returns (uint256) {
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

    function signAbeOkamotoMessage(
        uint256 u,
        uint256 s,
        uint256 e,
        uint256 x
    ) public view returns (uint256, uint256, uint256, uint256) {
        uint256 c = e - (ab.d % ab.q);
        uint256 r = u - (mulmod(c, x, ab.q) % ab.q);
        return (r, c, s, ab.d);
    }

    function unblindAbeOkamotoMessage(
        uint256 t1,
        uint256 t2,
        uint256 t3,
        uint256 t4,
        uint256 r,
        uint256 c,
        uint256 s
    ) public view returns (uint256, uint256, uint256, uint256) {
        uint256 rho = (r + (t1 % ab.q));
        uint256 omega = (c + (t2 % ab.q));
        uint256 sigma = (s + (t3 % ab.q));
        uint256 delta = (ab.d + (t4 % ab.q));
        return (rho, omega, sigma, delta);
    }

    function verifyAbeOkamotoSignature(
        uint256 y,
        uint256 z,
        address m,
        uint256 rho,
        uint256 omega,
        uint256 sigma,
        uint256 delta
    ) public view {
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

    /************************** Elgama ***************************/
    /**
     *
     * @param m Message sign
     * @param r Part of signature
     * @param s Part of signature
     * @param y Public key of signre
     */
    function verifyElgamaSignature(
        uint256 m,
        uint256 r,
        uint256 s,
        uint256 y
    ) public view {
        uint256 computeVerify = mulmod(
            Math.modExp(r, s, elgama.p),
            Math.modExp(y, r, elgama.p),
            elgama.p
        );

        uint256 hashMessage = uint256(keccak256(abi.encode(m)));
        require(Math.modExp(elgama.g, hashMessage, elgama.p) == computeVerify);
    }
}
