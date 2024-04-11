// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./BlindSchnorr.sol";

struct ReferMixer {
    BlindSchnoor bs;
    mapping(address => mapping(uint256 => bool)) referIdentify;
    mapping(uint256 => uint256) referMessage;
    mapping(uint256 => uint256) referSignature;
}
