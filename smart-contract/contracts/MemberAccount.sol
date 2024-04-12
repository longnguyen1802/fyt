// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Elgama.sol";
import "./IProtocol.sol";
import "./IMemberAccount.sol";

contract MemberAccount is IMemberAccount {
    // Normal account information
    address protocol;
    uint256 sendKey;
    uint256 receiveKey;

    // Money record
    uint256 totalURT;
    mapping(uint256 => MR) moneyRecord;

    // Sender support information
    uint256 pubKey;
    uint256 signNonce;
    uint256 signIndex;

    // Elgama signature for checking send/receive/refer request
    Elgama elgama;

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

    function processMR(uint256 index) external {
        require(msg.sender == protocol);
        require(moneyRecord[index].state == State.Lock);
        moneyRecord[index].state = State.InProcess;
    }

    function lockMR(uint256 index) external {
        require(msg.sender == protocol);
        moneyRecord[index].state = State.InProcess;
    }

    function unlockMR(uint256 index) external {
        require(msg.sender == protocol);
        require(moneyRecord[index].state == State.InProcess);
        moneyRecord[index].state = State.Unlock;
    }

    function getMoneyRecordState(uint256 index) public view returns (State) {
        return moneyRecord[index].state;
    }

    function getMRValue(uint256 index) public view returns (uint256) {
        return moneyRecord[index].money;
    }

    function sendReferRequest() external {}

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
