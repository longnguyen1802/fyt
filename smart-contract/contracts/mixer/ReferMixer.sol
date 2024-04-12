// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../cryptography/BlindSchnorr.sol";

struct ReferMixer {
    BlindSchnoor bs;
    mapping(address => mapping(uint256 => bool)) referIdentify;
    mapping(uint256 => uint256) referMessage;
    mapping(uint256 => uint256) referSignature;
}

function recordReferRequest(
    ReferMixer storage referMixer,
    address account,
    uint256 nonce
) {
    referMixer.referIdentify[account][nonce] = true;
}

function recordReferMessage(
    ReferMixer storage referMixer,
    address account,
    uint256 nonce,
    uint256 e
) {
    require(referMixer.referIdentify[account][nonce]);
    referMixer.referMessage[nonce] = e;
}

function recordReferSignature(
    ReferMixer storage referMixer,
    uint256 nonce,
    uint256 s
) {
    referMixer.referSignature[nonce] = s;
}

function verifyReferSignature(
    ReferMixer storage referMixer,
    address account,
    uint256 signerPubKey,
    uint256 e,
    uint256 s
) view {
    SchnorrSignature memory schSig = SchnorrSignature(e, s);
    // Check BlindSchnorr Signature
    verifySchnorrSignature(referMixer.bs, schSig, account, signerPubKey);
}
