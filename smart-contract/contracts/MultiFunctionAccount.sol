// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct Rational {
    uint128 numerator;
    uint128 denominator;
}

struct UTXO {
    int money;
    bool state;
    Rational protocolParams;
}

contract MultiFunctionAccount {
    address public sendKey;
    address public receiveKey;
    uint256 public pubKey;
    int public numBreakUTXO;
    UTXO[] unspentUTXO;
}
