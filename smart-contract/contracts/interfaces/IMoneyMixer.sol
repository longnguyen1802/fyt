// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../interfaces/IMemberAccount.sol";
import "../utilities/Time.sol";

interface IMoneyMixer {
    /**
     * @dev Records a send transaction.
     * @param account The account to record the transaction for.
     * @param index The index of the transaction.
     * @param e The value to be recorded.
     */
    function recordSendTransaction(
        address account,
        uint256 index,
        uint256 e
    ) external;

    /**
     * @dev Records a send signature.
     * @param account The account to record the signature for.
     * @param e The value to be recorded.
     * @param r The value to be recorded.
     */
    function recordSendSignature(
        address account,
        uint256 e,
        uint256 r
    ) external;

    /**
     * @dev Records a receive transaction.
     * @param account The account to record the transaction for.
     * @param money The amount of money to be recorded.
     * @param rho The value to be recorded.
     * @param delta The value to be recorded.
     * @param omega The value to be recorded.
     * @param sigma The value to be recorded.
     * @param signerPubKey The public key of the signer.
     */
    function recordReceiveTransaction(
        address account,
        uint256 money,
        uint256 rho,
        uint256 delta,
        uint256 omega,
        uint256 sigma,
        uint256 signerPubKey
    ) external;

    /**
     * @dev Moves the contract to the sign phase.
     */
    function moveToSignPhase() external;

    /**
     * @dev Moves the contract to the receive phase.
     */
    function moveToReceivePhase() external;

    /**
     * @dev Moves the contract to the validity check phase.
     */
    function moveToValidityCheckPhase() external;

    /**
     * @dev Resets the phase control.
     */
    function resetPhaseControl() external;
}
