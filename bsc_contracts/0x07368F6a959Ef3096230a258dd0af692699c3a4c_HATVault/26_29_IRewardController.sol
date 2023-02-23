// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRewardController {
    
    error EpochLengthZero();
    // Not enough rewards to transfer to user
    error NotEnoughRewardsToTransferToUser();

    event RewardControllerCreated(
        address _rewardToken,
        address _governance,
        uint256 _startBlock,
        uint256 _epochLength,
        uint256[24] _epochRewardPerBlock
    );
    event SetEpochRewardPerBlock(uint256[24] _epochRewardPerBlock);
    event SetAllocPoint(address indexed _vault, uint256 _prevAllocPoint, uint256 _allocPoint);
    event VaultUpdated(address indexed _vault, uint256 _rewardPerShare, uint256 _lastProcessedVaultUpdate);
    event UserBalanceCommitted(address indexed _vault, address indexed _user, uint256 _unclaimedReward, uint256 _rewardDebt);
    event ClaimReward(address indexed _vault, address indexed _user, uint256 _amount);

    /**
     * @notice Initializes the reward controller
     * @param _rewardToken The address of the ERC20 token to be distributed as rewards
     * @param _governance The hats governance address, to be given ownership of the reward controller
     * @param _startRewardingBlock The block number from which to start rewarding
     * @param _epochLength The length of a rewarding epoch
     * @param _epochRewardPerBlock The reward per block for each of the 24 epochs
     */
    function initialize(
        address _rewardToken,
        address _governance,
        uint256 _startRewardingBlock,
        uint256 _epochLength,
        uint256[24] calldata _epochRewardPerBlock
    ) external;

    /**
     * @notice Called by the owner to set the allocation points for a vault, meaning the
     * vault's relative share of the total rewards
     * @param _vault The address of the vault
     * @param _allocPoint The allocation points for the vault
     */
    function setAllocPoint(address _vault, uint256 _allocPoint) external;

    /**
    * @notice Update the vault's reward per share, not more then once per block
    * @param _vault The vault's address
    */
    function updateVault(address _vault) external;

    /**
    * @notice Called by the owner to set reward per epoch
    * Reward can only be set for epochs which have not yet started
    * @param _epochRewardPerBlock reward per block for each epoch
    */
    function setEpochRewardPerBlock(uint256[24] calldata _epochRewardPerBlock) external;

    /**
    * @notice Called by the vault to update a user claimable reward after deposit or withdraw.
    * This call should never revert.
    * @param _user The user address to updare rewards for
    * @param _sharesChange The user of shared the user deposited or withdrew
    * @param _isDeposit Whether user deposited or withdrew
    */
    function commitUserBalance(address _user, uint256 _sharesChange, bool _isDeposit) external;
    /**
    * @notice Transfer to the specified user their pending share of rewards.
    * @param _vault The vault address
    * @param _user The user address to claim for
    */
    function claimReward(address _vault, address _user) external;

    /**
    * @notice Calculate rewards for a vault by iterating over the history of totalAllocPoints updates,
    * and sum up all rewards periods from vault.lastRewardBlock until current block number.
    * @param _vault The vault address
    * @param _fromBlock The block from which to start calculation
    * @return reward The amount of rewards for the vault
    */
    function getVaultReward(address _vault, uint256 _fromBlock) external view returns(uint256 reward);

    /**
    * @notice Calculate the amount of rewards a user can claim for having contributed to a specific vault
    * @param _vault The vault address
    * @param _user The user for which the reward is calculated
    */
    function getPendingReward(address _vault, address _user) external view returns (uint256);

    /**
    * @notice Called by the owner to transfer any tokens held in this contract to the owner
    * @param _token The token to sweep
    * @param _amount The amount of token to sweep
    */
    function sweepToken(IERC20Upgradeable _token, uint256 _amount) external;

}