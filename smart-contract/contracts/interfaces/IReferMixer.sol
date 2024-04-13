// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../cryptography/BlindSchnorr.sol";

interface IReferMixer {
    function recordReferRequest(address account, uint256 nonce) external;
    function recordReferMessage(
        address account,
        uint256 nonce,
        uint256 e
    ) external;
    function recordReferSignature(uint256 nonce, uint256 s) external;
    function verifyReferSignature(
        address account,
        uint256 signerPubKey,
        uint256 e,
        uint256 s
    ) external view;
}
