// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./MemberAccount.sol";
import "./BlindSchnorr.sol";
import "./AbeOkamotoPartialBlind.sol";
import "./ReferMixer.sol";
import "./MoneyMixer.sol";
import "./Signer.sol";

struct DeploymentState {
    bool isDeploymentEnd;
    uint256 numInitialMember;
    uint256 endblock;
    bool firstSignerSetUp;
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

    // ************************************************** PROTOCOL ATTRIBUTE ***********************************************
    // Protocol params
    ProtocolParams params;
    // Deployment phase
    DeploymentState deployState;
    // All other phases
    RoundInfo roundInfo;

    // Keep track of member
    uint256 numberMember;
    mapping(address => bool) members;

    /*
        Constructor
        Set up all protocol parameters
     */
    constructor(
        uint256 _p,
        uint256 _q,
        uint256 _g,
        uint256 _Ms,
        uint256 _Md,
        uint256 numeParentFee,
        uint256 demoParentFee,
        uint256 _protocolFee,
        uint256 _joinFee,
        uint256 _signerDepositFee
    ) {
        params = ProtocolParams(
            _p,
            _q,
            _g,
            _Ms,
            _Md,
            Rational(numeParentFee, demoParentFee),
            _protocolFee,
            _joinFee,
            _signerDepositFee
        );
    }

    /********************************  DEPLOYMENT PHASE *********************************/
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
        deployState.numInitialMember++;
    }

    /*
    Close the inital member register state
    Check timestamp
    Can be call by anyone
    End the initial state
     */
    function closeDeploymentState() public {
        require(block.timestamp > state.deployTimeEnd);
        deployState.isDeploymentEnd = true;
    }

    /************************************ Signer Rotation Flow *****************************************/
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
        recordBidForSigner(signerInfo, account, signIndex);
    }

    function refundUnsuccessSigner() public {
        require(members[msg.sender]);
        removeUnsuccessRegister(signerInfo, msg.sender);
        //payable(msg.sender).transfer();
    }

    /****************************************** MAIN FLOW DO ROUND BY ROUND *****************************/
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

    /*  REFER WORKFLOW */

    /*
        STEP 1: Inner member send request to refer new member
     */
    function requestRefer() public {
        require(members[msg.sender]);
        emit RequestRefer(msg.sender);
    }
    /**
     *
     * @param account Address of member that want to make a refer
     * @param nonce Public nonce generate by Signer
     */
    function startRequestRefer(address account, uint256 nonce) public {
        require(msg.sender == signerInfo.currentSigner);
        recordReferRequest(referMixer, account, nonce);
    }

    /**
     * STEP 2: Signer generate nonce
     * @param nonce : Public nonce generate by signer
     * @param e :     Refer message (Blind)
     */
    function sendReferRequest(uint256 nonce, uint256 e) public {
        require(members[msg.sender]);
        recordReferMessage(referMixer, msg.sender, nonce, e);
    }
    /**
     * STEP 3: Signer sign the refer message
     * @param nonce : Public nonce generate by signer
     * @param s     : Refer signature
     */
    function signReferRequest(uint256 nonce, uint256 s) public {
        require(msg.sender == signerInfo.currentSigner);
        recordReferSignature(referMixer, nonce, s);
    }

    /**
     * STEP 4: Verification and onboard new member
     * @param e : Original message
     * @param s : Signature
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
        DISTRIBUTION MONEY WORKFLOW
     */

    /**
     * PHASE 1: Send transaction request
     * @param index : Index of the MR
     * @param e : Blind message
     */
    function sendTransaction(uint256 index, uint256 e) public {
        require(members[msg.sender]);
        recordSendTransaction(moneyMixer, msg.sender, index, e);
        emit SendTransactionRequest(msg.sender, index, e);
    }

    /**
     * PHASE 2: Signer sign the transaction send request
     * @param account : Address of the account send transaction
     * @param e : Blind message
     * @param r : Signature sign by signer
     */
    function signTransaction(address account, uint256 e, uint256 r) public {
        require(msg.sender == signerInfo.currentSigner);
        // Verify signer computation
        distributeMoneySignature[account][e] = r;
    }

    /**
     * PHASE 3: Send receive request
     * @param money : Amount of money in MR
     * 4 Signatures componnent
     * @param rho
     * @param delta
     * @param omega
     * @param sigma
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

    /**
     * PHASE 4: Validity check
     */
    function verifySigner() public {
        require(roundInfo.totalReceiveMoney == roundInfo.totalSendMoney);
        roundInfo.signerVerify = true;
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

    // function claimRoundMoney() public {

    // }
}
