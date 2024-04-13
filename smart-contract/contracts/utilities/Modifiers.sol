// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Modifiers {
    modifier nonNullAddress(address _address) {
        require(_address != address(0), "Address cannot be null");
        _;
    }
}
