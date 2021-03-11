pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./include/IERC20.sol";

import "./lib/Permission.sol";

abstract contract StakingBase is Permission {
    uint256 public startTime;
    uint256 public totalDuration;
    uint256 public totalReward;

    int256 public stakingMax = 10**30;

    mapping(address => int256) public stakingAmounts;
    mapping(address => int256) public stakingAdjusts;

    int256 public totalAmount;
    int256 public totalAdjust;

    constructor(
        uint256 _startTime,
        uint256 _duration,
        uint256 _reward
    ) {
        startTime = _startTime;
        totalDuration = _duration;
        totalReward = _reward;
    }

    function setStakingMax(int256 max) external CheckPermit("Admin") {
        stakingMax = max;
    }

    function getMineInfo(address owner)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            int256,
            int256,
            int256,
            int256
        )
    {
        return (startTime, totalDuration, totalReward, totalAmount, totalAdjust, stakingAmounts[owner], stakingAdjusts[owner]);
    }

    function _staking(address owner, int256 amount) internal {
        int256 newAmount = stakingAmounts[owner] + amount;
        require(newAmount >= 0 && newAmount < stakingMax, "invalid amount");

        uint256 _now = block.timestamp;
        if (_now > startTime && totalAmount != 0) {
            int256 reward;
            if (_now < startTime + totalDuration) {
                reward = int256((totalReward * (_now - startTime)) / totalDuration) + totalAdjust;
            } else {
                reward = int256(totalReward) + totalAdjust;
            }

            int256 adjust = reward * amount / totalAmount;
            stakingAdjusts[owner] += adjust;
            totalAdjust += adjust;
        }
        stakingAmounts[owner] = newAmount;
        totalAmount += amount;
    }

    function calcReward(address owner) public view returns (int256) {
        uint256 _now = block.timestamp;
        if (_now <= startTime) {
            return 0;
        }
        int256 amount = stakingAmounts[owner];
        int256 adjust = stakingAdjusts[owner];
        if (amount == 0) {
            return -adjust;
        }
        int256 reward;
        if (_now < startTime + totalDuration) {
            reward = int256((totalReward * (_now - startTime)) / totalDuration) + totalAdjust;
        } else {
            reward = int256(totalReward) + totalAdjust;
        }
        return (reward * amount) / totalAmount - adjust;
    }

    function _withdraw() internal returns (uint256) {
        int256 reward = calcReward(msg.sender);
        require(reward > 0, "no reward");

        stakingAdjusts[msg.sender] += reward;
        return uint256(reward);
    }

    function stopStaking() external CheckPermit("Admin") {
        uint256 _now = block.timestamp;
        require(_now < startTime + totalDuration, "staking over");

        uint256 tokenAmount;
        if (_now < startTime) {
            tokenAmount = totalReward;
            totalReward = 0;
            totalDuration = 1;
        } else {
            uint256 reward = (totalReward * (_now - startTime)) / totalDuration;
            tokenAmount = totalReward - reward;
            totalReward = reward;
            totalDuration = _now - startTime;
        }
        IERC20(manager.members("token")).transfer(manager.members("cashier"), tokenAmount);
    }
}
