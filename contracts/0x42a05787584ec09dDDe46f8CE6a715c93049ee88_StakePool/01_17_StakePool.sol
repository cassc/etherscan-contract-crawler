/*
    Copyright 2021 Memento Blockchain Pte. Ltd.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./IRewardsManager.sol";

/**
 * @title StakePool
 * @author DEXTF Protocol
 *
 * Contract for Stake Pools that allow token holders to stake their tokens
 * in exchange for more token rewards. Staked tokens and reward tokens may
 * not neccessarily be the same tokens. StakePool.sol contract works in
 * conjunction with a RewardsManager.sol contract that holds and distributes
 * the reward tokens to stakers. Deployer and owner of the StakePool.sol
 * has to ensure that the right Rewards Manager and Staked/Reward Token
 * addresses, as well as the reward token distribution rate per block, the
 * unlock and relock time (in minutes) for withdrawal and redemption of
 * stake dand reward tokens are passed to the Stake Pool on deployment
 * accordingly.
*/

contract StakePool is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // Contract address for the staked tokens
    IERC20 public stakedToken;
    // Contract address for the reward tokens
    IERC20 public rewardsToken;
    // Contract address for Rewards Manager
    IRewardsManager public rewardsManager;
    // Amount of rewards to be distributed per block
    uint256 public rewardsDistributionRate;
    // Internal calculation of rewards accrued per staked token
    uint256 private rewardsPerStakedToken;
    // Block which this stake pool contract was last updated at
    uint256 private lastUpdatedAt;
    // Total amount of tokens staked in this stake pool
    uint256 public totalStaked;
    // Unlock time set for this contract (in minutes)
    uint256 public unlockTime;
    // Relock time set for this contract (in minutes)
    uint256 public relockTime;

    /* ========== CONSTANTS ========== */

    uint256 public constant SAFE_MULTIPLIER = 1e18;

    /* ========== STRUCTS ========== */

    struct UserInfo {
        // Amount of tokens staked by user
        uint256 stakedAmount;
        // Calculation for tracking rewards owed to user based on stake changes
        uint256 rewardsDebt;
        // Calculation for accrued rewards to user not yet redeemed, based on rewardsDebt
        uint256 rewardsAccrued;
        // Total rewards redeemed by user
        uint256 rewardsRedeemed;
        // Unlock time stored as block timestamp
        uint256 unlockTime;
        // Relock time stored as block timestamp
        uint256 relockTime;
    }

    /* ========== MAPPINGS ========== */

    mapping(address => UserInfo) public userInfo;

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ActivateUnlock(address indexed user);
    event RewardRedeemed(address indexed user, uint256 reward);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakedToken,
        address _rewardsToken,
        address _rewardsManager,
        uint256 _rewardsDistributionRate,
        uint256 _unlockTime,
        uint256 _relockTime
    ) {
        stakedToken = IERC20(_stakedToken);
        rewardsToken = IERC20(_rewardsToken);
        rewardsManager = IRewardsManager(_rewardsManager);
        rewardsDistributionRate = _rewardsDistributionRate;
        unlockTime = _unlockTime;
        relockTime = _relockTime;
        rewardsPerStakedToken = 0;
        lastUpdatedAt = block.number;
    }

    /* ========== MODIFIERS ========== */

    /**
    * Modifier to check if user is allowed to withdraw or redeem tokens
    * @param _user      Address of staked user account
    */
    modifier whenNotLocked(address _user) {
        // If unlockTime == 0 it means we do not have any unlock time required
        if (unlockTime != 0) {
            require(userInfo[_user].unlockTime != 0, "Activate unlock for withdrawal and redemption window first");
            require(block.timestamp > userInfo[_user].unlockTime, "Unlock time still in progress");
            require(block.timestamp < userInfo[_user].relockTime, "Withdraw and redemption window has passed");
        }
        _;
    }

    /**
    * Modifier to update stake pool contract details. Triggered when staked tokens
    * amount changes.
    */
    modifier updatePool() {
        if (totalStaked > 0) {
            rewardsPerStakedToken = block.number.sub(lastUpdatedAt)
                                                .mul(rewardsDistributionRate)
                                                .mul(SAFE_MULTIPLIER)
                                                .div(totalStaked)
                                                .add(rewardsPerStakedToken);
        }
        lastUpdatedAt = block.number;
        _;
    }

    /* ========== VIEWS ========== */

    /**
    * Returns the amount of staked tokens of a user
    * @param _account           Address of a user
    * @return stakedAmount      Total amount staked by user
    */
    function balanceOf(address _account) external view returns (uint256) {
        return userInfo[_account].stakedAmount;
    }

    /**
    * Calculate the current rewards accrued per token staked
    * @return currentRewardsPerStakedToken      Current rewards per staked token
    */
    function currentRewardsPerStakedToken() public view returns (uint256) {
        if (totalStaked <= 0) {
          return rewardsDistributionRate;
        }

        return block.number.sub(lastUpdatedAt)
                           .mul(rewardsDistributionRate)
                           .mul(SAFE_MULTIPLIER)
                           .div(totalStaked)
                           .add(rewardsPerStakedToken);
    }

    /**
    * Returns the reward tokens currently accrued but not yet redeemed to a user
    * @param _account           Address of a user
    * @return rewardsEarned     Total rewards accrued to user
    */
    function rewardsEarned(address _account) public view returns (uint256) {
        return userInfo[_account].stakedAmount
                    .mul(currentRewardsPerStakedToken())
                    .sub(userInfo[_account].rewardsDebt)
                    .add(userInfo[_account].rewardsAccrued)
                    .div(SAFE_MULTIPLIER);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * Private function used for updating the user rewardsDebt variable
    * Called when user's stake changes
    * @param _account           Address of a user
    * @param _amount            Amount of new tokens staked or amount of tokens left in stake pool
    */
    function _updateUserRewardsDebt(address _account, uint256 _amount) private {
        userInfo[_account].rewardsDebt = userInfo[_account].rewardsDebt
                                            .add(_amount.mul(rewardsPerStakedToken));
    }

    /**
    * Private function used for updating the user rewardsAccrued variable
    * Called when user is withdrawing staked tokens
    * @param _account           Address of a user
    */
    function _updateUserRewardsAccrued(address _account) private {
        userInfo[_account].rewardsAccrued = userInfo[_account].rewardsAccrued
                                                .add(userInfo[_account].stakedAmount
                                                .mul(rewardsPerStakedToken)
                                                .sub(userInfo[_account].rewardsDebt));
        userInfo[_account].rewardsDebt = 0;
    }

    /**
    * External function called when a user wants to stake tokens
    * Called when user is depositing tokens to stake
    * @param _amount           Amount of tokens to stake
    */
    function stake(uint256 _amount) external nonReentrant whenNotPaused updatePool {
        require(_amount > 0, "Cannot stake 0");

        _updateUserRewardsDebt(msg.sender, _amount);
        userInfo[msg.sender].stakedAmount = userInfo[msg.sender].stakedAmount.add(_amount);

        totalStaked = totalStaked.add(_amount);
        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    /**
    * External function called when a user wants to unstake tokens
    * Called when user is withdrawing staked tokens
    * @param _amount           Amount of tokens to withdraw/unstake
    */
    function withdraw(uint256 _amount) public nonReentrant whenNotPaused whenNotLocked(msg.sender) updatePool {
        require(_amount > 0, "Cannot withdraw 0");

        _updateUserRewardsAccrued(msg.sender);
        userInfo[msg.sender].stakedAmount = userInfo[msg.sender].stakedAmount.sub(_amount);
        _updateUserRewardsDebt(msg.sender, userInfo[msg.sender].stakedAmount);

        totalStaked = totalStaked.sub(_amount);
        stakedToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    /**
    * External function called when a user wants to redeem accrued reward tokens
    */
    function redeemRewards() public nonReentrant whenNotPaused whenNotLocked(msg.sender) {
        uint256 rewards = rewardsEarned(msg.sender);

        if (rewards > 0) {
            userInfo[msg.sender].rewardsAccrued = 0;
            userInfo[msg.sender].rewardsRedeemed = userInfo[msg.sender].rewardsRedeemed.add(rewards);

            // Reset user's rewards debt, similar to as if user has just withdrawn and restake all
            userInfo[msg.sender].rewardsDebt = userInfo[msg.sender].stakedAmount
                                                    .mul(currentRewardsPerStakedToken());

            rewardsManager.transferRewardsToUser(msg.sender, rewards);

            emit RewardRedeemed(msg.sender, rewards);
        }
    }

    /**
    * External function called when a user wants to activate the unlock time to
    * withdraw staked towards or redeem reward tokens
    */
    function activateUnlockTime() external whenNotPaused {
      require(userInfo[msg.sender].unlockTime < block.timestamp, "Unlock time still in progress");

      userInfo[msg.sender].unlockTime = block.timestamp + unlockTime * 1 minutes;
      userInfo[msg.sender].relockTime = block.timestamp + (unlockTime + relockTime) * 1 minutes;
      emit ActivateUnlock(msg.sender);
    }

    /**
    * External function that combines the redemption of reward tokens and
    * withdrawing of all staked tokens at the same time
    */
    function exit() external {
        redeemRewards();
        withdraw(userInfo[msg.sender].stakedAmount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * Owner only function to update the rewards token distribution rate
    * @param _rate      Rate of rewards token distribution per block
    */
    function updateRewardsDistributionRate(uint256 _rate) external onlyOwner updatePool {
      require(_rate >= 0, "Rate cannot be less than 0");

      rewardsDistributionRate = _rate;
    }

    /**
    * Owner only function to update the unlock time for users to withdraw
    * staked tokens or redeem reward tokens. Can be 0 for no lock
    * @param _minutes      Unlock time in minutes
    */
    function updateUnlockTime(uint256 _minutes) external onlyOwner {
      unlockTime = _minutes;
    }

    /**
    * Owner only function to update the relock time for users to lock users
    * from withdrawing staked tokens or redeeming reward tokens
    * @param _minutes      Relock time in minutes
    */
    function updateRelockTime(uint256 _minutes) external onlyOwner {
      relockTime = _minutes;
    }
}