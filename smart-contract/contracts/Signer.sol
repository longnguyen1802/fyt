// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./MemberAccount.sol";

struct SignerInfo {
    address currentSigner;
    address nextSigner;
    uint256 nextSignerIndex;
    uint256 nextSignerRegisterEndBlock;
    mapping(address => bool) signerDeposit;
}

function getSignerSignKey(address signer) view returns (uint256) {
    return MemberAccount(signer).getSignKey();
}

function recordBidForSigner(
    SignerInfo storage signerInfo,
    address account,
    uint256 signIndex
) {
    require(signIndex < signerInfo.nextSignerIndex);
    signerInfo.nextSigner = account;
    signerInfo.nextSignerIndex = signIndex;
    signerInfo.signerDeposit[account] = true;
}

function removeUnsuccessRegister(
    SignerInfo storage signerInfo,
    address account
) {
    require(signerInfo.signerDeposit[account]);
    require(signerInfo.currentSigner != msg.sender);
    require(signerInfo.nextSigner != msg.sender);
    signerInfo.signerDeposit[msg.sender] = false;
}

function updateSignerRegisterEnd() {}
