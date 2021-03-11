pragma solidity ^0.8.0;

// SPDX-License-Identifier: Apache-2.0

abstract contract ContractOwner {
    address public contractOwner = msg.sender;
    
    modifier OwnerOnly {
        require(msg.sender == contractOwner, "only allow contract owner");
        _;
    }
}
