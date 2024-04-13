// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../cryptography/AbeOkamotoPartialBlind.sol";
import "../interfaces/IMemberAccount.sol";

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

function recordSendTransaction(
    MoneyMixer storage moneyMixer,
    address account,
    uint256 index,
    uint256 e
) {
    moneyMixer.distributeMoneyMessage[account][e] = index;
    IMemberAccount(account).processMR(index);
}

function recordSendSignature(
    MoneyMixer storage moneyMixer,
    address account,
    uint256 e,
    uint256 r
) {
    moneyMixer.distributeMoneySignature[account][e] = r;
}

function recordReceiveTransaction(
    MoneyMixer storage moneyMixer,
    address account,
    uint256 money,
    uint256 rho,
    uint256 delta,
    uint256 omega,
    uint256 sigma,
    uint256 signerPubKey
) {
    uint256 z = uint256(keccak256(abi.encode(money)));
    verifyAbeOkamotoSignature(
        moneyMixer.ab,
        signerPubKey,
        z,
        account,
        rho,
        omega,
        sigma,
        delta
    );

    moneyMixer.sendTransactionConfirm[account] += money;
    moneyMixer.totalReceiveMoney += money;
}
