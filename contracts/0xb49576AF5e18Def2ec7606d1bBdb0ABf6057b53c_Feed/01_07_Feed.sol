// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Sneed's Feed & Seed Staking 
 * 
 * This is a DeFi application that allows you to stake (deposit) tokens
 * and earn rewards over time.
 * 
 * Here's a simple explanation of what it does:
 * 
 * 1. Deposit Tokens: You can deposit your tokens into this contract. The contract
 *    keeps track of how many tokens you've deposited. 
 * 
 * 2. Earn Rewards: Once your tokens are deposited, you start earning rewards.
 *    The more tokens you deposit, the more rewards you earn.
 * 
 * 3. Claim Rewards: You can claim your earned rewards at any time. These rewards 
 *    are tokens that get added to your balance.
 * 
 * 4. Withdraw Tokens: You can also withdraw your tokens at any time. When you 
 *    withdraw, you get back the tokens you deposited plus any rewards you've 
 *    claimed.
 * 
 * 5. Fees: This contract has a 10% fee on both deposit and withdrawal. 9% of this fee 
 *    goes back into the pool to be distributed as rewards to stakers, and 1% is burned.
 * 
 * 6. Burn: Burning tokens is a way to decrease the total supply of the tokens, 
 *    which can help increase the value of remaining tokens.
 * 
 * Remember, in blockchain and DeFi, you have full control over your tokens. 
 * Only you can deposit, withdraw or claim rewards. This contract is just a tool
 * that helps you earn more from your tokens.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Feed is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public totalStaked;
    uint256 public countOfActiveStakers;
    uint256 private constant FEE_BASE = 10000; // 100% represented as 10000
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping(address => Staker) public stakers;

    uint256 public cumulativeRewardPerToken;

    struct Staker {
        uint256 stakedAmount;
        uint256 claimedRewardPerToken;
    }

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);
    event RewardsClaimed(address indexed who, uint256 amount);
    event Burn(address indexed who, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }
    
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");

        if(calculateReward(msg.sender) > 0) {
            _claimReward();
        }

        uint256 depositFee = _amount.mul(900).div(FEE_BASE); // 9% fee
        uint256 burnAmount = _amount.mul(100).div(FEE_BASE); // 1% burn
        uint256 netDeposit = _amount.sub(depositFee).sub(burnAmount);

        token.safeTransferFrom(msg.sender, address(this), _amount);
        token.safeTransfer(BURN_ADDRESS, burnAmount);

        Staker storage staker = stakers[msg.sender];

        if (staker.stakedAmount == 0) {
            countOfActiveStakers = countOfActiveStakers.add(1);
        }

        staker.stakedAmount = staker.stakedAmount.add(netDeposit);
        totalStaked = totalStaked.add(netDeposit);
        updateGlobalReward(depositFee);

        emit Deposit(msg.sender, _amount);
        emit Burn(msg.sender, burnAmount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");

        Staker storage staker = stakers[msg.sender];
        require(staker.stakedAmount >= _amount, "Insufficient staked balance");

        if(calculateReward(msg.sender) > 0) {
            _claimReward();
        }

        uint256 withdrawFee = _amount.mul(900).div(FEE_BASE); // 9% fee
        uint256 burnAmount = _amount.mul(100).div(FEE_BASE); // 1% burn
        uint256 netWithdraw = _amount.sub(withdrawFee).sub(burnAmount);

        token.safeTransfer(msg.sender, netWithdraw);
        token.safeTransfer(BURN_ADDRESS, burnAmount);

        staker.stakedAmount = staker.stakedAmount.sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        updateGlobalReward(withdrawFee);

        if (staker.stakedAmount == 0) {
            countOfActiveStakers = countOfActiveStakers.sub(1);
        }

        emit Withdraw(msg.sender, _amount);
        emit Burn(msg.sender, burnAmount);
    }

    function claimReward() public nonReentrant {
        _claimReward();
    }

    function _claimReward() private {
        Staker storage staker = stakers[msg.sender];
        uint256 reward = calculateReward(msg.sender);

        require(reward > 0, "No rewards to claim");

        staker.claimedRewardPerToken = cumulativeRewardPerToken;
        token.safeTransfer(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    function calculateReward(address _staker) public view returns (uint256) {
        Staker storage staker = stakers[_staker];
        uint256 newRewardPerToken = cumulativeRewardPerToken.sub(staker.claimedRewardPerToken);
        uint256 reward = staker.stakedAmount.mul(newRewardPerToken).div(FEE_BASE);
       
        return reward;
    }

    function updateGlobalReward(uint256 _reward) internal {
        if (totalStaked > 0) {
            uint256 rewardPerToken = _reward.mul(FEE_BASE).div(totalStaked);
            cumulativeRewardPerToken = cumulativeRewardPerToken.add(rewardPerToken);
        }
    }

    function getStakedAmount(address _staker) public view returns (uint256) {
        return stakers[_staker].stakedAmount;
    }

    function returnData(address _user) public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            totalStaked,
            countOfActiveStakers,
            getStakedAmount(_user),
            calculateReward(_user),
            token.balanceOf(_user)
        );
    }

}