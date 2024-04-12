// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./MemberAccount.sol";
import "./BlindSchnorr.sol";
import "./AbeOkamotoPartialBlind.sol";
import "./ReferMixer.sol";
import "./MoneyMixer.sol";

struct DeploymentState {
    bool isDeploymentEnd;
    uint256 deployTimeEnd;
}

struct ProtocolParams {
    // Protocol generator
    uint256 p;
    uint256 q;
    uint256 g;
    // Random number
    uint256 Ms;
    uint256 Md;
    // Percentage send to parent
    Rational parentFee;
    // Encode fee
    uint256 protocolFee;
    uint256 joinFee;
    uint256 signerDepositFee;
}

struct InitialState {
    uint256 endblock;
    bool isEnd;
}

struct SignerInfo {
    address currentSigner;
    address nextSigner;
    uint256 nextSignerIndex;
    uint256 nextSignerRegisterEndBlock;
    mapping(address => bool) signerDeposit;
}

struct RoundInfo {
    // Basic round infomation
    uint256 number;
    uint256 roundEnd;
    uint256 roundLong;
    bool isEnd;
    // Signer infomation
    SignerInfo signerInfo;
    bool signerVerify;
    // Refer mixer
    ReferMixer referMixer;
    // Money mixer
    MoneyMixer moneyMixer;
}

contract Protocol {
    // Event
    event RequestRefer(address indexed signer);
    event SendTransactionRequest(
        address indexed signer,
        uint256 index,
        uint256 e
    );

    // Protocol params
    ProtocolParams params;
    // Deployment phase
    DeploymentState state;
    InitialState initialState;
    // All other phases
    RoundInfo roundInfo;

    // Keep track of member
    uint256 numberMember;
    mapping(address => bool) members;

    // The random number that member send to signer at start of workflow is serve as identify

    /*
    Constructor
    Requirement:
        Set up protocol parameter
        Set up end block for initial member register
     */
    constructor() {}

    /*
    Register for initial member
    Check timestamp
    Contribute the protocol fee
    Set up the send key for account (optional sign key )
     */

    function initialMemberRegister() public payable {
        require(msg.value >= params.initalMemberFee);
        require(block.timestamp <= state.deployTimeEnd);
        // Need to check interface (later)
        members[msg.sender] = true;
    }

    /*
    Close the inital member register state
    Check timestamp
    Can be call by anyone
    End the initial state
     */
    function closeDeploymentState() public {
        require(block.timestamp > state.deployTimeEnd);
        state.isDeploymentEnd = true;
    }

    /*  Bid to become next signer
        Requirement :
            Account not being banned for signer (Caught cheat previously)
            Chose the smallest Index
            Increase the index of member being chose by current number member
     */
    function bidForNextSigner() public payable {
        require(members[msg.sender]);
        require(msg.value == signerInfo.signerDepositFee);
        uint256 signIndex = MemberAccount(msg.sender).getSignIndex();
        require(signIndex < signerInfo.nextSignerIndex);
        signerInfo.nextSigner = msg.sender;
        signerInfo.nextSignerIndex = signIndex;
        signerDeposit[msg.sender] = true;
    }

    function refundUnsuccessSigner() public {
        require(members[msg.sender]);
        require(signerDeposit[msg.sender]);
        require(signerInfo.currentSigner != msg.sender);
        require(signerInfo.nextSigner != msg.sender);
        signerDeposit[msg.sender] = false;
        payable(msg.sender).transfer(signerInfo.signerDepositFee);
    }

    /*
        Start a new round with new signer and allow for bid next signer 
        Requirement:
            Round not in process
     */
    function startNewRound() public {
        require(roundInfo.isEnd);
        require(signerInfo.nextSignerRegisterEndBlock <= block.timestamp);
        // Mofidy Signer info state
        signerInfo.nextSignerRegisterEndBlock += roundInfo.roundLong;
        signerInfo.currentSigner = signerInfo.nextSigner;
        signerInfo.nextSigner = address(0);
        MemberAccount(signerInfo.nextSigner).increaseSignerIndex(numberMember);
        // Modify Round info state
        roundInfo.isEnd = false;
        roundInfo.roundEnd += roundInfo.roundLong;
        roundInfo.totalReceiveMoney = 0;
        roundInfo.totalSendMoney = 0;
    }

    /*
        End current round
        Requirements:
            Timestamp require
            Call function to decide cheat signer
            Refund for signer
     */
    function endRound() public {
        require(roundInfo.roundEnd <= block.timestamp);
        require(roundInfo.isEnd == false);
        signerDeposit[signerInfo.currentSigner] = false;
        // Decide cheat signer
        // Increase signer index if cheat
        // Refund if not cheat;
        roundInfo.isEnd = true;
    }

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
    function requestRefer() public {
        require(members[msg.sender]);
        emit RequestRefer(msg.sender);
    }

    function startRequestRefer(address account, uint256 nonce) public {
        require(msg.sender == signerInfo.currentSigner);
        recordReferRequest(referMixer, account, nonce);
    }

    function sendReferRequest(uint256 nonce, uint256 e) public {
        require(members[msg.sender]);
        recordReferMessage(referMixer, msg.sender, nonce, e);
    }
    function signReferRequest(uint256 nonce, uint256 s) public {
        require(msg.sender == signerInfo.currentSigner);
        recordReferSignature(referMixer, nonce, s);
    }
    /*
        Onboard newmember to prococol
        Requirements:
            Check signature
            Check deposit
            Check timestamp (sign phase end)
        Create new MR for him and save join round
     */
    function onboardMember(uint256 e, uint256 s) public {
        // Pending check msg.value
        // Pending add protocol fee
        // Pending add join fee (Need an special type of MR)
        uint256 signerPubKey = MemberAccount(signerInfo.currentSigner)
            .getSignKey();
        verifyReferSignature(referMixer, msg.sender, signerPubKey, e, s);
        members[msg.sender] = true;
    }

    /*
        Interactive process, need to call from distribution workflow
        This include send blind message only
     */
    function sendTransaction(uint256 index, uint256 e) public {
        require(members[msg.sender]);
        recordSendTransaction(moneyMixer, msg.sender, index, e);
        emit SendTransactionRequest(msg.sender, index, e);
    }

    function signTransaction(address account, uint256 e, uint256 r) public {
        require(msg.sender == signerInfo.currentSigner);
        // Verify signer computation
        distributeMoneySignature[account][e] = r;
    }
    /*
        Provide signature for receive money
        Require sign process end
    */
    function receiveTransaction(
        uint256 money,
        uint256 rho,
        uint256 delta,
        uint256 omega,
        uint256 sigma
    ) public {
        uint256 signerPubKey = MemberAccount(signerInfo.currentSigner)
            .getSignKey();
        recordReceiveTransaction(
            moneyMixer,
            msg.sender,
            money,
            rho,
            delta,
            omega,
            sigma,
            signerPubKey
        );
    }

    function breakUTXO(uint256 index) public {
        require(roundInfo.signerVerify);
        require(members[msg.sender]);
        require(
            MemberAccount(msg.sender).getUTXOState(index) == State.InProcess
        );
        MemberAccount(msg.sender).lockUTXO(index);
        // Only get part of it
        //payable(msg.sender).transfer(MemberAccount(msg.sender).getUTXOValue(index));
    }

    /*
        Unforgery process
        Check the sum of send money and receive money to decide this round is success
     */
    function verifySigner() public {
        require(roundInfo.totalReceiveMoney == roundInfo.totalSendMoney);
        roundInfo.signerVerify = true;
    }

    // function claimRoundMoney() public {

    // }
}
