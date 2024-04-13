// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../cryptography/Elgama.sol";
import "../interfaces/IProtocol.sol";
import "../interfaces/IMemberAccount.sol";

contract MemberAccount is IMemberAccount {
    // Normal account information
    address protocol;
    uint256 sendKey;
    uint256 receiveKey;

    // Money record
    uint256 totalURT;
    mapping(uint256 => MR) moneyRecord;

    // Signer support information
    uint256 pubKey;
    uint256 signNonce;
    uint256 signIndex;
    uint256 signerDepositFee;

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

    /**
     *
     * @param nonce Nonce for refer request
     * @param e Message for refer request
     * @param sig_r Part of elgama signature
     * @param sig_s Part of elgama signature
     */
    function sendReferRequest(
        uint256 nonce,
        uint256 e,
        uint256 sig_r,
        uint256 sig_s
    ) external {
        uint256 m = uint256(keccak256(abi.encode(nonce, e)));
        verifyElgamaSignature(elgama, m, sig_r, sig_s, receiveKey);
        IProtocol(protocol).sendReferRequest(nonce, e);
    }

    function onBoard(
        uint256 e,
        uint256 s,
        uint256 sig_r,
        uint256 sig_s
    ) external {
        uint256 m = uint256(keccak256(abi.encode(e, s)));
        verifyElgamaSignature(elgama, m, sig_r, sig_s, receiveKey);
        IProtocol(protocol).onboardMember(e, s);
    }

    function sendTransaction(
        uint256 index,
        uint256 e,
        uint256 sig_r,
        uint256 sig_s
    ) external {
        // Call the interface
        uint256 m = uint256(keccak256(abi.encode(index, e)));
        verifyElgamaSignature(elgama, m, sig_r, sig_s, sendKey);
        IProtocol(protocol).sendTransaction(index, e);
    }

    function receiveTransaction(
        uint256 money,
        uint256 rho,
        uint256 delta,
        uint256 omega,
        uint256 sigma,
        uint256 sig_r,
        uint256 sig_s
    ) external {
        // Call the interface
        uint256 m = uint256(keccak256(abi.encode(rho, delta, omega, sigma)));
        verifyElgamaSignature(elgama, m, sig_r, sig_s, receiveKey);
        IProtocol(protocol).receiveTransaction(money, rho, delta, omega, sigma);
    }

    function signTransaction(
        address account,
        uint256 e,
        uint256 r,
        uint256 sig_r,
        uint256 sig_s
    ) external {
        // Call the interface
        uint256 m = uint256(keccak256(abi.encode(account, e, r)));
        verifyElgamaSignature(elgama, m, sig_r, sig_s, pubKey);
        IProtocol(protocol).signTransaction(account, e, r);
    }

    function bidSigner() external payable {
        require(msg.value == signerDepositFee);
        IProtocol(protocol).bidForNextSigner();
    }

    function claimRefundSigner() external {
        IProtocol(protocol).refundUnsuccessSigner();
    }

    receive() external payable {}
}
