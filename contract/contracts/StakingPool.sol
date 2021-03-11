pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./include/IERC20.sol";
import "./MultiStakingBase.sol";

contract StakingPool is MultiStakingBase {
    function staking(int256 amount) external payable {
        if (amount > 0) {
            require(msg.value == uint256(amount), "invalid msg.value");
        } else {
            address payable recipient = payable(msg.sender);
            recipient.transfer(uint256(-amount));
        }
        _staking(address(0), msg.sender, amount);
    }

    function staking(address poolAddr, int256 amount) external {
        bool success;
        IERC20 token = IERC20(poolAddr);
        if (amount > 0) {
            success = token.transferFrom(msg.sender, address(this), uint256(amount));
        } else {
            success = token.transfer(msg.sender, uint256(-amount));
        }
        require(success, "Payment failed");
        _staking(poolAddr, msg.sender, amount);
    }

    function withdraw(address poolAddr) external {
        uint256 reward = _withdraw(poolAddr);
        if (poolAddr == address(0)) {
            address payable recipient = payable(msg.sender);
            recipient.transfer(reward);
        } else {
            IERC20(manager.members("token")).transfer(msg.sender, reward);
        }
    }
}
