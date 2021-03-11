pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./ContractOwner.sol";

contract Manager is ContractOwner {
    mapping(string => address) public members;

    mapping(address => mapping(string => bool)) public permits;

    function setMember(string memory name, address member) external OwnerOnly {
        members[name] = member;
    }

    function setPermit(
        address addr,
        string memory permit,
        bool enable
    ) external OwnerOnly {
        permits[addr][permit] = enable;
    }

}
