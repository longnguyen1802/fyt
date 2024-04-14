// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./account/Signer.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IMemberAccount.sol";
import "./interfaces/IMoneyMixer.sol";
import "./interfaces/IReferMixer.sol";

contract Protocol is IProtocol {

    modifier nonNullAddress(address _address) {
        require(_address != address(0), "Address cannot be null");
        _;
    }

    // Events
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

    // Address of mixer
    address immutable mixerControl;
    address moneyMixer;
    address referMixer;

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
        uint256 _signerDepositFee,
        uint256 deploymentLength,
        uint256 _roundLong
    ) {
        mixerControl = msg.sender;
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

        deployState = DeploymentState(
            false,
            0,
            block.number + deploymentLength,
            false
        );

        roundInfo.number = 0;
        roundInfo.roundLong = _roundLong;
        roundInfo.isEnd = true;

        numberMember = 0;

    }

    function setUpMixer(address _moneyMixer,address _referMixer) nonNullAddress(_moneyMixer) nonNullAddress(_referMixer) external {
        require(msg.sender == mixerControl);
        moneyMixer = _moneyMixer;
        referMixer = _referMixer;
    }
    /********************************  DEPLOYMENT PHASE *********************************/
    /*
    Register for initial member
    Check timestamp
    Contribute the protocol fee
    Set up the send key for account (optional sign key )
     */

    function initialMemberRegister() public payable {
        require(msg.value >= params.protocolFee);
        require(block.number <= deployState.endblock);
        members[msg.sender] = true;
        if(deployState.numInitialMember == 0) {
            roundInfo.signerInfo.nextSigner = msg.sender;
        }
        deployState.numInitialMember++;
    }

    /*
    Close the inital member register state
    Check timestamp
    Can be call by anyone
    End the initial state
     */
    function closeDeploymentState() public {
        require(block.number > deployState.endblock);
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
        require(deployState.isDeploymentEnd);
        require(!roundInfo.isEnd);
        require(members[msg.sender]);
        require(msg.value == params.signerDepositFee);
        uint256 signIndex = IMemberAccount(msg.sender).getSignIndex();
        recordBidForSigner(roundInfo.signerInfo, msg.sender, signIndex);
    }

    function refundUnsuccessSigner() public {
        require(members[msg.sender]);
        removeUnsuccessRegister(roundInfo.signerInfo, msg.sender);
        payable(msg.sender).transfer(params.signerDepositFee);
    }

    /****************************************** MAIN FLOW DO ROUND BY ROUND *****************************/
    /*
        Start a new round with new signer and allow for bid next signer 
        Requirement:
            Round not in process
     */
    function startNewRound() public {
        require(deployState.isDeploymentEnd);
        require(roundInfo.isEnd);
        // Mofidy Signer info state
        roundInfo.signerInfo.currentSigner = roundInfo.signerInfo.nextSigner;
        roundInfo.signerInfo.nextSigner = address(0);
        // Modify Round info state
        roundInfo.isEnd = false;
        roundInfo.roundEnd += roundInfo.roundLong;
        IReferMixer(referMixer).resetPhaseControl();
        IMoneyMixer(moneyMixer).resetPhaseControl();
        IMemberAccount(roundInfo.signerInfo.nextSigner).increaseSignerIndex(
            numberMember
        );
        
    }

    /*
        End current round
        Requirements:
            Timestamp require
            Call function to decide cheat signer
            Refund for signer
     */
    function endRound() public {
        require(roundInfo.roundEnd <= block.number);
        require(roundInfo.isEnd == false);
        roundInfo.signerInfo.signerDeposit[
            roundInfo.signerInfo.currentSigner
        ] = false;
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
        require(msg.sender == roundInfo.signerInfo.currentSigner);
        IReferMixer(referMixer).recordReferRequest(account, nonce);
    }

    /**
     * STEP 2: Signer generate nonce
     * @param nonce : Public nonce generate by signer
     * @param e :     Refer message (Blind)
     */
    function sendReferRequest(uint256 nonce, uint256 e) public {
        require(members[msg.sender]);
        IReferMixer(referMixer).recordReferMessage(msg.sender, nonce, e);
    }
    /**
     * STEP 3: Signer sign the refer message
     * @param nonce : Public nonce generate by signer
     * @param s     : Refer signature
     */
    function signReferRequest(uint256 nonce, uint256 s) public {
        require(msg.sender == roundInfo.signerInfo.currentSigner);
        IReferMixer(referMixer).recordReferSignature(nonce, s);
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
        uint256 signerPubKey = IMemberAccount(
            roundInfo.signerInfo.currentSigner
        ).getSignKey();
        IReferMixer(referMixer).verifyReferSignature(
            msg.sender,
            signerPubKey,
            e,
            s
        );
        members[msg.sender] = true;
        numberMember+=1;
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
        emit SendTransactionRequest(msg.sender, index, e);
        IMoneyMixer(moneyMixer).recordSendTransaction(msg.sender, index, e);
    }

    /**
     * PHASE 2: Signer sign the transaction send request
     * @param account : Address of the account send transaction
     * @param e : Blind message
     * @param r : Signature sign by signer
     */
    function signTransaction(address account, uint256 e, uint256 r) public {
        require(msg.sender == roundInfo.signerInfo.currentSigner);
        // Verify signer computation
        IMoneyMixer(moneyMixer).recordSendSignature(account, e, r);
    }

    /**
     * PHASE 3: Send receive request
     * @param money : Amount of money in MR
     * 4 Signatures componnent
     * @param rho     Part of signature
     * @param delta   Part of signature
     * @param omega   Part of signature
     * @param sigma   Part of signature
     */
    function receiveTransaction(
        uint256 money,
        uint256 rho,
        uint256 delta,
        uint256 omega,
        uint256 sigma
    ) public {
        uint256 signerPubKey = IMemberAccount(
            roundInfo.signerInfo.currentSigner
        ).getSignKey();
        IMoneyMixer(moneyMixer).recordReceiveTransaction(
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
        roundInfo.signerVerify = true;
        IMoneyMixer(moneyMixer).doValidityCheck();
    }

    function formNewMR(uint256 amount) public {
        require(members[msg.sender]);
        require(roundInfo.signerVerify);
        IMoneyMixer(moneyMixer).spendReceiveTransactionMoney(msg.sender,amount);
        IMemberAccount(msg.sender).createMR(amount);
    }

    /*************************** Phase control *************************************/
    function startSignPhaseForReferMixer() external {
        IReferMixer(referMixer).moveToSignPhase();
    }

    function startOnboardPhaseForReferMixer() external {
        IReferMixer(referMixer).moveToOnboardPhase();
    }

    function startSignPhaseForMoneyMixer() external {
        IMoneyMixer(moneyMixer).moveToSignPhase();
    }

    function startReceivePhaseForMoneyMixer() external {
        IMoneyMixer(moneyMixer).moveToReceivePhase();
    }

    function startValidityCheckPhaseForMoneyMixer() external {
        IMoneyMixer(moneyMixer).moveToValidityCheckPhase();
    }
}
