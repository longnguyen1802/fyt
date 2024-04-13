// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../cryptography/BlindSchnorr.sol";

contract ReferMixer {
    modifier onlyProtocol() {
        require(
            msg.sender == protocol,
            "Only the protocol can call this function."
        );
        _;
    }

    modifier nonNullAddress(address _address) {
        require(_address != address(0), "Address cannot be null");
        _;
    }

    BlindSchnoor bs;
    address immutable protocol;

    mapping(address => mapping(uint256 => bool)) referIdentify;
    mapping(uint256 => uint256) referMessage;
    mapping(uint256 => uint256) referSignature;

    constructor(address _protocol) nonNullAddress(_protocol) {
        protocol = _protocol;
    }

    function recordReferRequest(
        address account,
        uint256 nonce
    ) external onlyProtocol {
        referIdentify[account][nonce] = true;
    }

    function recordReferMessage(
        address account,
        uint256 nonce,
        uint256 e
    ) external onlyProtocol {
        require(referIdentify[account][nonce]);
        referMessage[nonce] = e;
    }

    function recordReferSignature(
        uint256 nonce,
        uint256 s
    ) external onlyProtocol {
        referSignature[nonce] = s;
    }

    function verifyReferSignature(
        address account,
        uint256 signerPubKey,
        uint256 e,
        uint256 s
    ) public view {
        SchnorrSignature memory schSig = SchnorrSignature(e, s);
        // Check BlindSchnorr Signature
        verifySchnorrSignature(bs, schSig, account, signerPubKey);
    }
}
