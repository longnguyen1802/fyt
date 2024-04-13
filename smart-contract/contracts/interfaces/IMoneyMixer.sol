// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IMoneyMixer {
    function recordSendTransaction(
        address account,
        uint256 index,
        uint256 e
    ) external;
    function recordSendSignature(
        address account,
        uint256 e,
        uint256 r
    ) external;
    function recordReceiveTransaction(
        address account,
        uint256 money,
        uint256 rho,
        uint256 delta,
        uint256 omega,
        uint256 sigma,
        uint256 signerPubKey
    ) external;
}
