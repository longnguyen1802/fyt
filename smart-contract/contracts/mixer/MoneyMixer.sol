// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../interfaces/IMoneyMixer.sol";
import "../interfaces/ICryptography.sol";

/* Phase
 * 1: Send phase (Only accept send transaction)
 * 2: Sign phase (Only signer allow to sign transaction)
 * 3: Receive phase (Only receive transaction allow)
 * 4: Verify signer phase
 */

contract MoneyMixer is IMoneyMixer {
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
    address immutable cryptography;
    PhaseControl phaseControl;
    uint256 totalSendMoney;
    uint256 totalReceiveMoney;
    mapping(address => mapping(uint256 => uint256)) distributeMoneyMessage;
    mapping(address => mapping(uint256 => uint256)) distributeMoneySignature;
    mapping(address => uint256) receiveTransactionConfirm;

    constructor(
        address _protocol,
        address _cryptography,
        uint256 _phaseLength
    ) nonNullAddress(_protocol) nonNullAddress(_cryptography) {
        protocol = _protocol;
        cryptography = _cryptography;
        totalSendMoney = 0;
        totalReceiveMoney = 0;
        phaseControl = PhaseControl(4, _phaseLength, block.number);
    }

    function recordSendTransaction(
        address account,
        uint256 index,
        uint256 e
    ) external onlyProtocol {
        require(phaseControl.currentPhase == 1);
        distributeMoneyMessage[account][e] = index;
        totalSendMoney += IMemberAccount(account).getMRValue(index);
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
        receiveTransactionConfirm[account] += money;
        totalReceiveMoney += money;
        require(
            ICryptography(cryptography).verifyAbeOkamotoSignature(
                signerPubKey,
                z,
                account,
                rho,
                omega,
                sigma,
                delta
            )
        );
    }

    function doValidityCheck() external view onlyProtocol {
        require(phaseControl.currentPhase >= 4);
        require(totalReceiveMoney == totalSendMoney);
    }

    function spendReceiveTransactionMoney(
        address account,
        uint256 amount
    ) external onlyProtocol {
        require(receiveTransactionConfirm[account] >= amount);
        receiveTransactionConfirm[account] -= amount;
    }
    /********************************* Phase control ****************************/
    function moveToSignPhase() external onlyProtocol {
        require(phaseControl.currentPhase == 1, "Not in send phase");
        checkCurrentPhaseEnd(phaseControl, block.number);
        moveToNextPhase(phaseControl, block.number);
    }

    function moveToReceivePhase() external onlyProtocol {
        require(phaseControl.currentPhase == 2, "Not in sign phase");
        checkCurrentPhaseEnd(phaseControl, block.number);
        moveToNextPhase(phaseControl, block.number);
    }

    function moveToValidityCheckPhase() external onlyProtocol {
        require(phaseControl.currentPhase == 3, "Not in receive check phase");
        checkCurrentPhaseEnd(phaseControl, block.number);
        moveToNextPhase(phaseControl, block.number);
    }
    // New round start
    function resetPhaseControl() external onlyProtocol {
        require(phaseControl.currentPhase == 4, "Not in final phase");
        resetPhase(phaseControl, block.number);
    }
}
