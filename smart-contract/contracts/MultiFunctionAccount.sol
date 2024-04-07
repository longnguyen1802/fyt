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

// interface AccountInterface {

// }
contract MultiFunctionAccount {
    uint256 pubKey;
    // For money workflow
    uint256 signNonce;
    uint256 sendKey;
    uint256 receiveKey;
    int numBreakUTXO;
    UTXO[] unspentUTXO;
    uint256 signIndex;
    constructor(
        uint256 newPubKey,
        uint256 newSendKey,
        uint256 newReceiveKey,
        uint256 newSignNonce
    ) {
        pubKey = newPubKey;
        sendKey = newSendKey;
        receiveKey = newReceiveKey;
        numBreakUTXO = 0;
        unspentUTXO = new UTXO[](0);
        signIndex = block.timestamp;
        signNonce = newSignNonce;
    }

    function getSignIndex() public view returns (uint256) {
        return signIndex;
    }
    function increaseSignerIndex(uint256 amount) external {
        signIndex += amount;
    }

    function getSignKey() public view returns (uint256) {
        return pubKey;
    }
}
