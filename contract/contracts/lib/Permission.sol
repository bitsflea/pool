pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./ContractOwner.sol";
import "./Manager.sol";

abstract contract Permission is ContractOwner {
    modifier CheckPermit(string memory permit) {
        require(manager.permits(msg.sender, permit), "no permit");
        _;
    }

    Manager public manager;

    function setManager(address addr) external OwnerOnly {
        require(addr != address(0), "zero address");
        manager = Manager(addr);
    }
}
