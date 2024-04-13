// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../cryptography/AbeOkamotoPartialBlind.sol";
import "../interfaces/IMemberAccount.sol";
import "../utilities/Time.sol";
import "../utilities/Modifiers.sol";

/* Phase
 * 1: Send phase (Only accept send transaction)
 * 2: Sign phase (Only signer allow to sign transaction)
 * 3: Receive phase (Only receive transaction allow)
 * 4: Verify signer phase
 */

contract MoneyMixer {
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

    address immutable protocol;
    AbeOkamotoBlind ab;
    PhaseControl phaseControl;
    uint256 totalSendMoney;
    uint256 totalReceiveMoney;
    bool isSendState;
    bool isReceiveState;
    mapping(address => mapping(uint256 => uint256)) distributeMoneyMessage;
    mapping(address => mapping(uint256 => uint256)) distributeMoneySignature;
    mapping(address => uint256) sendTransactionConfirm;

    constructor(address _protocol) nonNullAddress(_protocol) {
        protocol = _protocol;
        //ab = _ab;
        //phaseControl = _phaseControl;
        totalSendMoney = 0;
        totalReceiveMoney = 0;
        isSendState = false;
        isReceiveState = false;
    }

    function recordSendTransaction(
        address account,
        uint256 index,
        uint256 e
    ) external onlyProtocol {
        require(phaseControl.currentPhase == 1);
        distributeMoneyMessage[account][e] = index;
        IMemberAccount(account).processMR(index);
    }

    function recordSendSignature(
        address account,
        uint256 e,
        uint256 r
    ) external onlyProtocol {
        require(phaseControl.currentPhase == 2);
        distributeMoneySignature[account][e] = r;
    }

    function recordReceiveTransaction(
        address account,
        uint256 money,
        uint256 rho,
        uint256 delta,
        uint256 omega,
        uint256 sigma,
        uint256 signerPubKey
    ) external onlyProtocol {
        require(phaseControl.currentPhase == 3);
        uint256 z = uint256(keccak256(abi.encode(money)));
        verifyAbeOkamotoSignature(
            ab,
            signerPubKey,
            z,
            account,
            rho,
            omega,
            sigma,
            delta
        );

        sendTransactionConfirm[account] += money;
        totalReceiveMoney += money;
    }
}
