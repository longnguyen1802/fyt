// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

enum State {
    Initial,
    Lock,
    InProcess,
    Unlock
}
interface IMemberAccount {
    struct MR {
        uint256 money;
        State state;
    }

    struct Rational {
        uint128 numerator;
        uint128 denominator;
    }

    function getSignIndex() external view returns (uint256);
    function increaseSignerIndex(uint256 amount) external;
    function getSignKey() external view returns (uint256);
    function processMR(uint256 index) external;
    function lockMR(uint256 index) external;
    function unlockMR(uint256 index) external;
    function getMoneyRecordState(uint256 index) external view returns (State);
    function getMRValue(uint256 index) external view returns (uint256);
    function createMR(uint256 amount) external;
    function sendReferRequest(
        uint256 nonce,
        uint256 e,
        uint256 sigR,
        uint256 sigS
    ) external;
    function onBoard(uint256 e, uint256 s, uint256 sigR, uint256 sigS) external;

    function registerInitialMember(uint256 value) external payable;

    function sendTransaction(
        uint256 index,
        uint256 e,
        uint256 sigR,
        uint256 sigS
    ) external;
    function receiveTransaction(
        uint256 money,
        uint256 rho,
        uint256 delta,
        uint256 omega,
        uint256 sigma,
        uint256 sigR,
        uint256 sigS
    ) external;

    function signTransaction(
        address account,
        uint256 e,
        uint256 r,
        uint256 sigR,
        uint256 sigS
    ) external;

    function bidSigner() external payable;
    function claimRefundSigner() external;
}
