//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.17;

interface IStaking {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address receiver, uint amount) external;
}

contract WStaking is Ownable {
    uint public tokensPerDay;
    uint public totalStaked;
    bool public status;

    struct Profile {
        uint amount;
        uint start;
        uint lastClaim;
    }

    address public StakingToken;
    mapping(address => Profile) public stakers;

    constructor(address stakingToken) {
        StakingToken = stakingToken;
        tokensPerDay = 2e18;
    }

    function setEmissionPerDay(uint amount) public onlyOwner {
        tokensPerDay = amount;
    }

    function setStakingStatus(bool _status) public onlyOwner {
        status = _status;
    }

    function stake(uint amount) public {
        require(status, "Staking is not started yet");
        IStaking(StakingToken).transferFrom(msg.sender, address(this), amount);
        if (stakers[msg.sender].start == 0) {
            stakers[msg.sender] = Profile(
                amount,
                block.timestamp,
                block.timestamp
            );
        } else {
            stakers[msg.sender].amount += amount;
        }
        totalStaked += amount;
    }

    function unstake(uint amount) public {
        require(stakers[msg.sender].amount >= amount, "not enough tokens!");
        uint rewards = getRewards(msg.sender);
        stakers[msg.sender].amount -= amount;
        stakers[msg.sender].lastClaim = block.timestamp;
        if (stakers[msg.sender].amount == 0) {
            stakers[msg.sender].start = 0;
            stakers[msg.sender].lastClaim = 0;
            stakers[msg.sender].start = 0;
        }
        IStaking(StakingToken).transfer(msg.sender, amount);
        IStaking(StakingToken).mint(msg.sender, rewards);
        totalStaked -= amount;
    }

    function getRewards(address staker) public view returns (uint256) {
        if (stakers[staker].amount == 0) {
            return 0;
        }
        if (stakers[staker].lastClaim == 0 || stakers[staker].start == 0) {
            return 0;
        }
        if (stakers[staker].lastClaim == block.timestamp) {
            return 0;
        }
        return
            tokensPerDay *
            (((block.timestamp - stakers[staker].lastClaim) / 1 days));
    }

    function getTotalStaked(address staker) public view returns (uint256) {
        return stakers[staker].amount;
    }

    function getStakingStartTime(address staker) public view returns (uint) {
        return stakers[staker].start;
    }

    function getStakerLastClaimTim(address staker) public view returns (uint) {
        return stakers[staker].lastClaim;
    }

    function nextRewardIn(address staker) public view returns (uint) {
        if (stakers[staker].amount == 0) {
            return 0;
        }
        if (stakers[staker].lastClaim == 0 || stakers[staker].start == 0) {
            return 0;
        }
        if (stakers[staker].lastClaim == block.timestamp) {
            return 1 days;
        }
        return 1 days - (block.timestamp - stakers[staker].lastClaim);
    }
}