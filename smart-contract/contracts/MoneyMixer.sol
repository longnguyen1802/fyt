// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./AbeOkamotoPartialBlind.sol";

struct MoneyMixer {
    AbeOkamotoBlind ab;
    mapping(address => mapping(uint256 => uint256)) distributeMoneyMessage;
    mapping(address => mapping(uint256 => uint256)) distributeMoneySignature;
    mapping(address => uint256) sendTransactionConfirm;
    uint256 totalSendMoney;
    uint256 totalReceiveMoney;
    bool isSendState;
    bool isReceiveState;
}
