// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum State {
    Lock,
    InProcess,
    Unlock
}

struct Rational {
    uint128 numerator;
    uint128 denominator;
}

struct URT {
    uint256 money;
    State state;
}

contract MemberAccount {
    // Normal account information
    address protocol;
    uint256 sendKey;
    uint256 receiveKey;

    // Money record
    uint256 totalURT;
    mapping(uint256 => URT) moneyRecord;

    // Sender support information
    uint256 pubKey;
    uint256 signNonce;
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

    function processURT(uint256 index) external {
        require(msg.sender == protocol);
        require(moneyRecord[index].state == State.Lock);
        moneyRecord[index].state = State.InProcess;
    }

    function lockURT(uint256 index) external {
        require(msg.sender == protocol);
        moneyRecord[index].state = State.InProcess;
    }

    function unlockURT(uint256 index) external {
        require(msg.sender == protocol);
        require(moneyRecord[index].state == State.InProcess);
        moneyRecord[index].state = State.Unlock;
    }

    function getmoneyRecordtate(uint256 index) public view returns (State) {
        return moneyRecord[index].state;
    }

    function getURTValue(uint256 index) public view returns (uint256) {
        return moneyRecord[index].money;
    }

    function sendReferRequest() external {}

    function signReferRequest() external {}

    function onBoard() external {}

    function sendTransaction() external {
        // Call the interface
    }

    function receiveTransaction() external {
        // Call the interface
    }

    function signTransaction() external {
        // Call the interface
    }

    function bidSigner() external {}

    function claimRefundSigner() external {}
}
