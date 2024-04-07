// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./MultiFunctionAccount.sol";
import "./BlindSchnorr.sol";

struct DeploymentState {
    bool isDeploymentEnd;
    uint256 deployTimeEnd;
}

struct ProtocolParams {
    BlindSchnoor bs;
    uint256 initalMemberFee;
    Rational parentFee;
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
    uint256 signerDepositFee;
}

struct RoundInfo {
    uint256 number;
    uint256 roundEnd;
    uint256 roundLong;
    SignerInfo signerInfo;
    bool isSendState;
    bool isReceiveState;
    bool isEnd;
}

contract Protocol {
    event RequestRefer(address indexed signer);

    ProtocolParams params;
    InitialState initialState;
    RoundInfo roundInfo;
    uint256 numberMember;
    DeploymentState state;
    SignerInfo signerInfo;
    mapping(address => bool) members;
    mapping(address => bool) signerDeposit;

    mapping(uint256 => uint256) referMessage;
    mapping(uint256 => uint256) distributeMoneyMessage;

    mapping(uint256 => uint256) referSignature;
    mapping(uint256 => uint256) distributeMoneySignature;
    // The random number that member send to signer at start of workflow is serve as identify
    mapping(address => mapping(uint256 => bool)) referIdentify;
    mapping(address => mapping(uint256 => bool)) distributeMoneyIdentify;
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
        uint256 signIndex = MultiFunctionAccount(msg.sender).getSignIndex();
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
        signerInfo.nextSignerRegisterEndBlock += roundInfo.roundLong;
        roundInfo.isEnd = false;
        roundInfo.roundEnd += roundInfo.roundLong;
        signerInfo.currentSigner = signerInfo.nextSigner;
        signerInfo.nextSigner = address(0);
        MultiFunctionAccount(signerInfo.nextSigner).increaseSignerIndex(
            numberMember
        );
        roundInfo.isEnd = false;
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
        referIdentify[account][nonce] = true;
    }

    function sendReferRequest(uint256 nonce, uint256 e) public {
        require(members[msg.sender]);
        require(referIdentify[msg.sender][nonce]);
        referMessage[nonce] = e;
    }
    function signReferRequest(uint256 nonce, uint256 s) public {
        require(msg.sender == signerInfo.currentSigner);
        referSignature[nonce] = s;
    }
    /*
        Onboard newmember to prococol
        Requirements:
            Check signature
            Check deposit
            Check timestamp (sign phase end)
        Create new UTXO for him and save join round
     */
    function onboardMember(uint256 e, uint256 s) public {
        SchnorrSignature memory schSig = SchnorrSignature(e, s);
        // Check BlindSchnorr Signature
        require(
            verifySignature(
                bs,
                schSig,
                msg.sender,
                MultiFunctionAccount(signerInfo.currentSigner).getSignKey()
            )
        );
        members[msg.sender] = true;
    }

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
}
