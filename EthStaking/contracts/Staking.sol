// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract EthStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint;

    // Info of each user.
    struct UserInfo {
        uint amount;         // How many ETHs the user has provided.
        uint rewardDebt;     // Reward debt.
    }

    // Info of each pool.
    struct PoolInfo {
        uint lastRewardTime;    // Last block timestamp that RewardToken distribution occurs.
        uint accTokenPerShare;   // Accumulated RewardToken per share, times 1e12.
        uint tokenPerSec;        // Reward amount per sec.
        uint balance;            // pool ETH balance.
    }

    PoolInfo public pool;
    mapping(address => UserInfo) public userInfo;

    uint public endTime;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event RewardLockedUp(address indexed user, uint amountLockedUp);

    constructor() {
        pool.lastRewardTime = block.timestamp;
    }

    function pendingRewards(address _user) public view returns (uint) {
        UserInfo storage user = userInfo[_user];
        uint accTokenPerShare = pool.accTokenPerShare;
        uint rewardTime = (block.timestamp <= endTime ) ? block.timestamp : endTime;
        
        if (rewardTime > pool.lastRewardTime && pool.balance != 0 ) {
            uint periods = rewardTime.sub(pool.lastRewardTime);
            uint tokenReward = periods.mul(pool.tokenPerSec);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(pool.balance));
            console.log("Pending accTokenPerShare: %d", accTokenPerShare);
        
        }
        
        uint pending = user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
        console.log("Pending rewards: %d", pending);
        
        return pending;
    }

    function updatePool() public {
        uint rewardTime = (block.timestamp <= endTime ) ? block.timestamp : endTime;
        console.log("rewardTime: %d, %d, %d", rewardTime, endTime, pool.lastRewardTime);
        
        if (rewardTime <= pool.lastRewardTime) {
            return;
        }

        if (pool.balance == 0) {
            pool.lastRewardTime = rewardTime;
            return;
        }

        uint periods = rewardTime.sub(pool.lastRewardTime);
        uint tokenReward = periods.mul(pool.tokenPerSec);
        
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e12).div(pool.balance));
        pool.lastRewardTime = rewardTime;
    }

    function deposit() payable external nonReentrant {
        require(msg.value > 0, "Invalid deposit amount");
        
        UserInfo storage user = userInfo[msg.sender];
        
        updatePool();

        pool.balance = pool.balance.add(msg.value);
        user.amount = user.amount.add(msg.value);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        
        console.log("RewardDebt: %d", user.rewardDebt);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "You didn't deposit here");

        updatePool();
        uint amount = user.amount;
        user.amount = 0;

        uint rewards = amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        user.rewardDebt = 0;
        pool.balance = pool.balance.sub(amount);

        payable(msg.sender).transfer(amount + rewards);

        emit Withdraw(msg.sender, amount);
    }

    function depositRewards(uint _rewardPeriods) external payable onlyOwner {
        require( msg.value > 0 , "err _amount=0");
        
        if (endTime > 0) {
            require(_rewardPeriods > endTime.sub(block.timestamp), "Invalid Parameters");
        }

        endTime = block.timestamp.add(_rewardPeriods);

        updatePool();

        uint rewardAmount = address(this).balance.sub(pool.balance);
        
        pool.tokenPerSec = rewardAmount.div(_rewardPeriods);
        console.log("TokenPerSec is %s ", pool.tokenPerSec);
    }

    function manageTreasury() external onlyOwner {
        require(block.timestamp > endTime, "can recover only staking end.");

        payable(msg.sender).transfer(address(this).balance);
    }
}