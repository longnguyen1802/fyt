// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./MultiFunctionAccount.sol";

struct ProtocolParams {
    uint256 p;
    uint256 q;
    // Group genenrator
    uint256 g;
    uint256 initalMemberFee;
    Rational parentFee;
}

struct InitialState {
    uint256 endblock;
    bool isEnd;
}

struct SignerInfo {
    address currentSigner;
    uint256 nextSignerRegisterEndBlock;
    uint256 currentSignerRegisterMaxIndex;
    bool isSignerRegisterState;
}

struct RoundInfo {
    uint256 number;
    SignerInfo signerInfo;
    bool isSendState;
    bool isReceiveState;
    bool isEnd;
}

contract EntryWorkflow {}

contract DistributionWorkflow {}

contract Protocol {
    ProtocolParams params;
    InitialState initialState;
    RoundInfo roundInfo;
    // call two other contract
    // rotated signer
    uint256 numberMember;

    /*
    Constructor
    Requirement:
        Set up protocol parameter
        Set up end block for initial member register
     */
    constructor(){

    }

    /*
    Register for initial member
    Check timestamp
    Contribute the protocol fee
    Set up the send key for account (optional sign key )
     */

    function initialMemberRegister() public {}

    /*
    Close the inital member register state
    Check timestamp
    Can be call by anyone
    End the initial state
     */
    function closeInitialState() public {}


    /*  Bid to become next signer
        Requirement :
            Account not being banned for signer (Caught cheat previously)
            Chose the smallest Index
            Increase the index of member being chose by current number member
     */
    function bidForNextSigner() public {}

    /*
        Start a new round with new signer and allow for bid next signer 
        Requirement:
            Round not in process
     */
    function startNewRound() public {}

    /*
        End current round
        Requirements:
            Timestamp require
            Call function to decide cheat signer
            Refund for signer
     */
    function endRound() public {}

    /*
        End the send phase and noone can send in current round after this
        Requirements:
            Timestamp require
    */
    function endSendPhase() public {}

    /*
        End the send phase and noone can send in current round after this
        Requirements:
            Timestamp require
            Check signer requirement
            Define chear signer
    */
    function endSignPhase() public {}

    /*
        Inner member send request to refer new member
     */
    function requestRefer() public {}

    /*
        Onboard newmember to prococol
        Requirements:
            Check signature
            Check deposit
            Check timestamp (sign phase end)
        Create new UTXO for him and save join round
     */
    function onboardMember() public {}

    /*
        Interactive process, need to call from distribution workflow
        This include send blind message only
     */
    function sendTransaction() public {}

    /*
        Provide signature for receive money
        Require sign process end
    */
    function receiveTransaction() public {}

    /*
        Unforgery process
        Check the sum of send money and receive money to decide this round is success
     */
    function verifySigner() public {}

    /*
        If the round end success with verifySigner, people can claim money before round end.
        Timestamp require
        Refund for unsuccess signer register
     */
    function refundSigner() public {}
}

/*
How to implement hash function
A chain hash is ok

 */
