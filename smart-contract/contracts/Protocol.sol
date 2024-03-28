// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./MultiFunctionAccount.sol";

struct ProtocolParams {
    uint256 p;
    uint256 q;
    // Group genenrator
    uint256 g;
}

contract EntryWorkflow {}

contract DistributionWorkflow {}

contract Protocol {
    // call two other contract
    // rotated signer
    MultiFunctionAccount signer;
    uint256 roundNumber;
    uint256 numberMember;
    uint256 indexLastSigner;
    bool inRoundProcess;
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
        Or claim money if verifySigner fail and money from Signer deposit
     */
    function claimMoney() public {}
}

/*
How to implement hash function
A chain hash is ok

 */
