// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./BlindSchnorr.sol";

struct ReferMixer {
    BlindSchnoor bs;
    mapping(address => mapping(uint256 => bool)) referIdentify;
    mapping(uint256 => uint256) referMessage;
    mapping(uint256 => uint256) referSignature;
}

function recordReferRequest(
    ReferMixer referMixer,
    address account,
    uint256 nonce
) public {
    referMixer.referIdentify[account][nonce] = true;
}

function recordReferMessage(
    ReferMixer referMixer,
    address account,
    uint256 nonce,
    uint256 e
) {
    require(referMixer.referIdentify[account][nonce]);
    referMixer.referMessage[nonce] = e;
}

function recordReferSignature(
    ReferMixer referMixer,
    uint256nonce,
    uint256 s
) public {
    referMixer.referSignature[nonce] = s;
}

function verifyReferSignature(
    ReferMixer referMixer,
    address account,
    uint256 signerPubKey,
    uint256 e,
    uint256 s
) public {
    SchnorrSignature memory schSig = SchnorrSignature(e, s);
    // Check BlindSchnorr Signature
    require(
        verifySchnorrSignature(referMixer.bs, schSig, account, signerPubKey)
    );
}
