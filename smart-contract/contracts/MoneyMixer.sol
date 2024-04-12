// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./AbeOkamotoPartialBlind.sol";
import "./MemberAccount.sol";

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
    MoneyMixer moneyMixer,
    address account,
    uint256 index,
    uint256 e
) public {
    moneyMixer.distributeMoneyMessage[account][e] = index;
    MemberAccount(account).processUTXO(index);
}

function recordSendSignature(
    MoneyMixer moneyMixer,
    address account,
    uint256 e,
    uint256 r
) public {
    moneyMixer.distributeMoneySignature[account][e] = r;
}

function recordReceiveTransaction(
    MoneyMixer moneyMixer,
    address account,
    uint256 money,
    uint256 rho,
    uint256 delta,
    uint256 omega,
    uint256 sigma,
    uint256 signerPubKey
) public {
    uint256 z = keccak256(abi.encode(money));
    require(
        verifyAbeOkamotoSignature(
            moneyMixer.ab,
            signerPubKey,
            z,
            account,
            rho,
            omega,
            sigma,
            delta
        )
    );
    moneyMixer.sendTransactionConfirm[account] += money;
    moneyMixer.totalReceiveMoney += money;
}
