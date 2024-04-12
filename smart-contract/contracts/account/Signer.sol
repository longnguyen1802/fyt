// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../interfaces/IMemberAccount.sol";
import "../interfaces/IProtocol.sol";

function getSignerSignKey(address signer) view returns (uint256) {
    return IMemberAccount(signer).getSignKey();
}

function recordBidForSigner(
    IProtocol.SignerInfo storage signerInfo,
    address account,
    uint256 signIndex
) {
    require(signIndex < signerInfo.nextSignerIndex);
    signerInfo.nextSigner = account;
    signerInfo.nextSignerIndex = signIndex;
    signerInfo.signerDeposit[account] = true;
}

function removeUnsuccessRegister(
    IProtocol.SignerInfo storage signerInfo,
    address account
) {
    require(signerInfo.signerDeposit[account]);
    require(signerInfo.currentSigner != msg.sender);
    require(signerInfo.nextSigner != msg.sender);
    signerInfo.signerDeposit[msg.sender] = false;
}

function updateSignerRegisterEnd() {}
