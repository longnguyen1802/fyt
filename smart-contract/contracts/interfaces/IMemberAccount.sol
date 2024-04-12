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
    function sendReferRequest() external;
    function onBoard() external;
    function sendTransaction() external;
    function receiveTransaction() external;
    function signTransaction() external;
    function bidSigner() external;
    function claimRefundSigner() external;
}
