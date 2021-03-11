pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./include/IERC20.sol";
import "./lib/Permission.sol";

abstract contract MultiStakingBase is Permission {
    struct Pool {
        uint64 startTime;
        uint64 duration;
        uint256 totalReward;
        int256 stakingMax;
        int256 totalAmount;
        int256 totalAdjust;
        mapping(address => int256) stakingAmounts;
        mapping(address => int256) stakingAdjusts;
    }

    mapping(address => Pool) pools;

    function addPool(
        address _poolAddr,
        uint64 _startTime,
        uint64 _duration,
        uint256 _reward
    ) external CheckPermit("Admin") {
        require(pools[_poolAddr].startTime == 0, "Pool already exists");

        Pool storage pool = pools[_poolAddr];
        pool.startTime = _startTime;
        pool.duration = _duration;
        pool.totalReward = _reward;
        pool.stakingMax = 10**30;
    }

    function deletePool(address poolAddr) external CheckPermit("Admin") {
        require(pools[poolAddr].startTime != 0, "Pool does not exist");

        Pool storage pool = pools[poolAddr];
        require(pool.totalReward == 0, "Pools that have already started cannot be deleted");

        delete pools[poolAddr];
    }

    function setStakingMax(address pool, int256 max) external CheckPermit("Admin") {
        require(pools[pool].startTime != 0, "Pool does not exist");
        pools[pool].stakingMax = max;
    }

    function getMineInfo(address poolAddr, address owner)
        external
        view
        returns (
            uint64,
            uint64,
            uint256,
            int256,
            int256,
            int256,
            int256
        )
    {
        if (pools[poolAddr].startTime == 0) return (0, 0, 0, 0, 0, 0, 0);
        Pool storage pool = pools[poolAddr];
        int256 stakingAmounts = pool.stakingAmounts[owner];
        int256 stakingAdjusts = pool.stakingAdjusts[owner];
        int256 totalAdjust = pool.totalAdjust;
        int256 totalAmount = pool.totalAmount;
        uint256 totalReward = pool.totalReward;
        uint64 duration = pool.duration;
        uint64 startTime = pool.startTime;
        return (startTime, duration, totalReward, totalAmount, totalAdjust, stakingAmounts, stakingAdjusts);
    }

    function _staking(
        address poolAddr,
        address owner,
        int256 amount
    ) internal {
        Pool storage pool = pools[poolAddr];
        require(pool.startTime != 0, "Pool does not exist");

        int256 newAmount = pool.stakingAmounts[owner] + amount;
        require(newAmount >= 0 && newAmount < pool.stakingMax, "invalid amount");

        uint256 _now = block.timestamp;
        if (_now > pool.startTime && pool.totalAmount != 0) {
            int256 reward;
            if (_now < pool.startTime + pool.duration) {
                reward = int256((pool.totalReward * (_now - pool.startTime)) / pool.duration) + pool.totalAdjust;
            } else {
                reward = int256(pool.totalReward) + pool.totalAdjust;
            }
            int256 adjust = (reward * amount) / pool.totalAmount;
            pool.stakingAdjusts[owner] += adjust;
            pool.totalAdjust += adjust;
        }
        pool.stakingAmounts[owner] = newAmount;
        pool.totalAmount += amount;
    }

    function calcReward(address poolAddr, address owner) public view returns (int256) {
        Pool storage pool = pools[poolAddr];
        uint256 _now = block.timestamp;
        if (_now <= pool.startTime) {
            return 0;
        }
        int256 amount = pool.stakingAmounts[owner];
        int256 adjust = pool.stakingAdjusts[owner];
        if (amount == 0) {
            return -adjust;
        }
        int256 reward;
        if (_now < pool.startTime + pool.duration) {
            reward = int256((pool.totalReward * (_now - pool.startTime)) / pool.duration) + pool.totalAdjust;
        } else {
            reward = int256(pool.totalReward) + pool.totalAdjust;
        }
        return (reward * amount) / pool.totalAmount - adjust;
    }

    function _withdraw(address poolAddr) internal returns (uint256) {
        int256 reward = calcReward(poolAddr, msg.sender);
        require(reward > 0, "no reward");

        pools[poolAddr].stakingAdjusts[msg.sender] += reward;
        return uint256(reward);
    }

    function stopStaking(address poolAddr) external CheckPermit("Admin") {
        uint256 _now = block.timestamp;
        Pool storage pool = pools[poolAddr];
        require(_now < pool.startTime + pool.duration, "staking over");

        uint256 tokenAmount;
        if (_now < pool.startTime) {
            tokenAmount = pool.totalReward;
            pool.totalReward = 0;
            pool.duration = 1;
        } else {
            uint256 reward = (pool.totalReward * (_now - pool.startTime)) / pool.duration;
            tokenAmount = pool.totalReward - reward;
            pool.totalReward = reward;
            pool.duration = uint64(_now - pool.startTime);
        }
        if (poolAddr == address(0)) {
            address payable cashier = payable(manager.members("cashier"));
            cashier.transfer(tokenAmount);
        } else {
            IERC20(manager.members("token")).transfer(manager.members("cashier"), tokenAmount);
        }
    }
}
