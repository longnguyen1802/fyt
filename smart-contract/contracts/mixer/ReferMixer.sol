// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../interfaces/ICryptography.sol";
import "../interfaces/IReferMixer.sol";
import "../utilities/Time.sol";

contract ReferMixer is IReferMixer {
  modifier onlyProtocol() {
    require(msg.sender == protocol, "Only the protocol can call this function.");
    _;
  }

  modifier nonNullAddress(address _address) {
    require(_address != address(0), "Address cannot be null");
    _;
  }

  address immutable cryptography;
  address immutable protocol;
  PhaseControl phaseControl;

  mapping(address => mapping(uint256 => bool)) public referIdentify;
  mapping(uint256 => uint256) public referMessage;
  mapping(uint256 => uint256) public referSignature;

  constructor(
    address _protocol,
    address _cryptography,
    uint256 _phaseLength
  ) nonNullAddress(_protocol) nonNullAddress(_cryptography) {
    protocol = _protocol;
    cryptography = _cryptography;
    phaseControl = PhaseControl(3, _phaseLength, block.number);
  }

  function recordReferRequest(address account, uint256 nonce) external onlyProtocol {
    require(phaseControl.currentPhase == 1, "Not in refer phase");
    referIdentify[account][nonce] = true;
  }

  function recordReferMessage(address account, uint256 nonce, uint256 e) external onlyProtocol {
    require(referIdentify[account][nonce], "Member not make refer request");
    require(phaseControl.currentPhase == 1, "Not in refer phase");
    referMessage[nonce] = e;
  }

  function recordReferSignature(uint256 nonce, uint256 s) external onlyProtocol {
    require(phaseControl.currentPhase == 2, "Not in sign phase");
    referSignature[nonce] = s;
  }

  function verifyReferSignature(
    address account,
    uint256 signerPubKey,
    uint256 e,
    uint256 s
  ) public {
    require(phaseControl.currentPhase >= 3, "Not in onboard phase");
    // Check BlindSchnorr Signature
    require(
      ICryptography(cryptography).verifySchnorrSignature(e, s, account, signerPubKey),
      "Invalid Schnoor signature"
    );
  }

  /********************************* Phase control ****************************/
  function moveToSignPhase() external onlyProtocol {
    require(phaseControl.currentPhase == 1, "Not in refer phase");
    checkCurrentPhaseEnd(phaseControl, block.number);
    moveToNextPhase(phaseControl, block.number);
  }

  function moveToOnboardPhase() external onlyProtocol {
    require(phaseControl.currentPhase == 2, "Not in sign phase");
    checkCurrentPhaseEnd(phaseControl, block.number);
    moveToNextPhase(phaseControl, block.number);
  }

  // New round start
  function resetPhaseControl() external onlyProtocol {
    require(phaseControl.currentPhase == 3, "Not in final phase");
    resetPhase(phaseControl, block.number);
  }

  function getCurrentPhase() public view returns (uint256) {
    return phaseControl.currentPhase;
  }
}
