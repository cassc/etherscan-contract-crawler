// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../interfaces/IStakingPoolRewarder.sol";
import "../interfaces/IStakingPools.sol";

/**
 * @title StakingPools
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice A contract for staking tokens in pools in exchange for rewards.
 * @dev The contract provides functionality for users to stake tokens in specific pools, earn rewards and claim them. The rewards are managed by a separate rewarder contract.
 *      The contract uses OpenZeppelin's Ownable for managing ownership and upgradeability to allow for future improvements without disrupting the contract's main operations.
 */
contract StakingPools is OwnableUpgradeable, IStakingPools {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Emitted when a new staking pool is created
     * @dev Logs the newly created pool's ID, the staked token, option contract, start block, end block, and reward per block
     * @param poolId The ID of the newly created pool
     * @param token The address of the token to be staked
     * @param optionContract The address of the option contract associated with the pool
     * @param startBlock The block number from which staking begins
     * @param endBlock The block number at which staking ends
     * @param rewardPerBlock The reward to be distributed per block for the pool
     */
    event PoolCreated(
        uint256 indexed poolId,
        address indexed token,
        address indexed optionContract,
        uint256 startBlock,
        uint256 endBlock,
        uint256 rewardPerBlock
    );

    /**
     * @notice Emitted when a staking pool's end block is extended
     * @dev Logs the pool's ID, its old end block and the new extended end block
     * @param poolId The ID of the pool
     * @param oldEndBlock The old end block of the pool
     * @param newEndBlock The new end block after extension
     */
    event PoolEndBlockExtended(uint256 indexed poolId, uint256 oldEndBlock, uint256 newEndBlock);

    /**
     * @notice Emitted when a staking pool's reward rate is changed
     * @dev Logs the pool's ID, its old reward per block and the new reward per block
     * @param poolId The ID of the pool
     * @param oldRewardPerBlock The old reward per block of the pool
     * @param newRewardPerBlock The new reward per block of the pool
     */
    event PoolRewardRateChanged(uint256 indexed poolId, uint256 oldRewardPerBlock, uint256 newRewardPerBlock);

    /**
     * @notice Emitted when the rewarder contract address is changed
     * @dev Logs the old rewarder address and the new rewarder address
     * @param oldRewarder The old rewarder contract address
     * @param newRewarder The new rewarder contract address
     */
    event RewarderChanged(address oldRewarder, address newRewarder);

    /**
     * @notice Emitted when tokens are staked in a pool
     * @dev Logs the pool's ID, the staker's address, the staked token's address, and the staked amount
     * @param poolId The ID of the pool
     * @param staker The address of the staker
     * @param token The address of the staked token
     * @param amount The amount of tokens staked
     */
    event Staked(uint256 indexed poolId, address indexed staker, address token, uint256 amount);

    /**
     * @notice Emitted when tokens are unstaked from a pool
     * @dev Logs the pool's ID, the staker's address, the staked token's address, and the unstaked amount
     * @param poolId The ID of the pool
     * @param staker The address of the staker
     * @param token The address of the staked token
     * @param amount The amount of tokens unstaked
     */
    event Unstaked(uint256 indexed poolId, address indexed staker, address token, uint256 amount);

    /**
     * @notice Emitted when rewards are redeemed from a pool
     * @dev Logs the pool's ID, the staker's address, the rewarder's address, and the redeemed reward amount
     * @param poolId The ID of the pool
     * @param staker The address of the staker
     * @param rewarder The address of the rewarder
     * @param amount The amount of rewards redeemed
     */
    event RewardRedeemed(uint256 indexed poolId, address indexed staker, address rewarder, uint256 amount);

    /**
     * @notice Emitted when the active state of a pool is changed
     * @dev Logs the pool's ID and its new active state
     * @param poolId The ID of the pool
     * @param isActive The new active state of the pool
     */
    event IsActiveChanged(uint256 indexed poolId, bool isActive);

    /**
     * @notice Emitted when the factory address is changed
     * @dev Logs the old factory address and the new factory address
     * @param oldFactory The old factory address
     * @param newFactory The new factory address
     */
    event FactoryChanged(address oldFactory, address newFactory);

    /**
     * @notice Represents a staking pool
     * @dev Contains pool details including start and end block for reward accumulation, reward per block, and the staking token's address
     */
    struct PoolInfo {
        uint256 startBlock; // the block from which rewards accumulation starts
        uint256 endBlock; // the block at which rewards accumulation ends
        uint256 rewardPerBlock; // the total rewards given to the pool per block
        address poolToken; // the address of the SNIPER token being staked in the pool
        address optionContract; // the address of the Option the SNIPER being staked in the pool belongs to
        bool isActive; // whether the pool is or is not open for staking
    }

    /**
     * @notice Represents a pool's staking data
     * @dev Contains information about total staked amount, accumulated reward per share, and the last block at which the accumulated reward was updated
     */
    struct PoolData {
        uint256 totalStakeAmount; // the total amount of tokens staked in the pool
        uint256 accuRewardPerShare; // the total amount of rewards divided with precision by the total number of tokens staked
        uint256 accuRewardLastUpdateBlock; // the block number at which accuRewardPerShare was last updated
    }

    /**
     * @notice Represents a user's staking data in a pool
     * @dev Contains information about the amount of tokens staked by the user, pending rewards, and the accumulated reward per share at the user's last staking/unstaking action
     */
    struct UserData {
        uint256 stakeAmount; // amount of tokens the user has in stake
        uint256 pendingReward; // amount of reward that can be redeemed by the user up to his latest action
        uint256 entryAccuRewardPerShare; // the accuRewardPerShare value at the user's last stake/unstake action
        uint256 entryTime; // the timestamp of the block the user entered the pool
    }

    /**
     * @notice The factory contract address
     * @dev Stores the address of the factory contract responsible for creating option contracts
     */
    address public optionFactory;

    /**
     * @notice The ID of the last created pool
     * @dev Stores the ID of the last created pool. The first pool has an ID of 1.
     */
    uint256 public lastPoolId;

    /**
     * @notice The rewarder contract
     * @dev An instance of IStakingPoolRewarder which handles reward logic
     */
    IStakingPoolRewarder public rewarder;

    /**
     * @notice Maps a pool ID to its PoolInfo struct
     * @dev Contains details for each staking pool
     */
    mapping(uint256 => PoolInfo) public poolInfos;

    /**
     * @notice Maps a pool ID to its PoolData struct
     * @dev Contains staking data for each pool
     */
    mapping(uint256 => PoolData) public poolData;

    /**
     * @notice Maps a pool ID to a mapping of an address to its UserData struct
     * @dev Contains user staking data for each pool
     */
    mapping(uint256 => mapping(address => UserData)) public userData;

    /**
     * @notice A constant used for precision loss prevention
     * @dev A large constant to keep precision intact when dealing with very small amounts
     */
    uint256 private constant ACCU_REWARD_MULTIPLIER = 10**20;

    /**
     * @notice Constant for the `transfer` function selector
     * @dev Bytes4 constant for the `transfer(address,uint256)` function selector to be used in calling ERC20 contracts
     */
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    /**
     * @notice Constant for the `approve` function selector
     * @dev Bytes4 constant for the `approve(address,uint256)` function selector to be used in calling ERC20 contracts
     */
    bytes4 private constant APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));

    /**
     * @notice Constant for the `transferFrom` function selector
     * @dev Bytes4 constant for the `transferFrom(address,address,uint256)` function selector to be used in calling ERC20 contracts
     */
    bytes4 private constant TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    /**
     * @notice Ensures the pool exists
     * @dev Checks if the pool with the specified ID exists
     */
    modifier onlyPoolExists(uint256 poolId) {
        require(poolInfos[poolId].endBlock > 0, "StakingPools: pool not found");
        _;
    }

    /**
     * @notice Ensures the pool is active
     * @dev Checks if the current block number is within the start and end block of the pool and if the pool is active
     */
    modifier onlyPoolActive(uint256 poolId) {
        require(
            block.number >= poolInfos[poolId].startBlock &&
                block.number < poolInfos[poolId].endBlock &&
                poolInfos[poolId].isActive,
            "StakingPools: pool not active"
        );
        _;
    }

    /**
     * @notice Ensures the pool has not ended
     * @dev Checks if the current block number is less than the end block of the pool
     */
    modifier onlyPoolNotEnded(uint256 poolId) {
        require(block.number < poolInfos[poolId].endBlock, "StakingPools: pool ended");
        _;
    }

    /**
     * @notice Ensures only the option contract can call the function
     * @dev Checks if the caller is the option contract associated with the pool
     */
    modifier onlyOptionContract(uint256 poolId) {
        require(msg.sender == poolInfos[poolId].optionContract, "StakingPools: only option contract");
        _;
    }

    /**
     * @notice Ensures only the owner or the factory contract can call the function
     * @dev Checks if the caller is the owner of the contract or the factory contract
     */
    modifier onlyOwnerOrFactory() {
        require(
            msg.sender == optionFactory || msg.sender == owner(),
            "StakingPools: caller is not the optionFactory or owner"
        );
        _;
    }

    /**
     * @notice Fetches detailed information for a specific pool
     * @dev This function simply returns the PoolInfo struct from the poolInfos mapping
     * @param poolId The ID of the pool for which to fetch information
     * @return PoolInfo struct containing detailed information about the pool
     */
    function getPoolInfo(uint256 poolId) external view returns (PoolInfo memory) {
        return poolInfos[poolId];
    }

    /**
     * @notice Calculates the pending reward for a specific user in a specific pool
     * @dev This function calculates the pending reward for a user by using the accuRewardPerShare,
     *      the amount the user has staked and the user's pendingReward
     * @param poolId The ID of the pool
     * @param staker The address of the user
     * @return The calculated pending reward for the user
     */
    function getPendingReward(uint256 poolId, address staker) external view returns (uint256) {
        UserData memory currentUserData = userData[poolId][staker];
        PoolInfo memory currentPoolInfo = poolInfos[poolId];
        PoolData memory currentPoolData = poolData[poolId];

        uint256 latestAccuRewardPerShare = currentPoolData.totalStakeAmount > 0
            ? currentPoolData.accuRewardPerShare.add(
                MathUpgradeable
                .min(block.number, currentPoolInfo.endBlock)
                .sub(currentPoolData.accuRewardLastUpdateBlock)
                .mul(currentPoolInfo.rewardPerBlock)
                .mul(ACCU_REWARD_MULTIPLIER)
                .div(currentPoolData.totalStakeAmount)
            )
            : currentPoolData.accuRewardPerShare;

        return
            currentUserData.pendingReward.add(
                currentUserData.stakeAmount.mul(latestAccuRewardPerShare.sub(currentUserData.entryAccuRewardPerShare)).div(
                    ACCU_REWARD_MULTIPLIER
                )
            );
    }

    /**
     * @notice Fetches the amount staked by a specific user in a specific pool
     * @dev This function returns the stakeAmount from the UserData struct
     *      in the userData mapping for the user in the specified pool
     * @param user The address of the user
     * @param poolId The ID of the pool
     * @return The amount staked by the user in the pool
     */
    function getStakingAmountByPoolID(address user, uint256 poolId) external view override returns (uint256) {
        return userData[poolId][user].stakeAmount;
    }

    /**
     * @notice Initializer function for StakingPools contract
     * @dev Calls the initializer of the parent Ownable contract. Only callable once.
     */
    function __StakingPools_init() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Creates a new staking pool
     * @dev The function will create a new pool with the provided parameters and emit a PoolCreated event
     * @param token The token that can be staked in the pool
     * @param optionContract The address of the option contract associated with the pool
     * @param startBlock The block at which staking starts
     * @param endBlock The block at which staking ends
     * @param rewardPerBlock The amount of reward token distributed per block
     */
    function createPool(
        address token,
        address optionContract,
        uint256 startBlock,
        uint256 endBlock,
        uint256 rewardPerBlock
    ) external override onlyOwnerOrFactory {
        require(token != address(0), "StakingPools: zero address");
        require(optionContract != address(0), "StakingPools: zero address");
        require(startBlock > block.number && endBlock > startBlock, "StakingPools: invalid block range");
        require(rewardPerBlock > 0, "StakingPools: reward must be positive");

        uint256 newPoolId = ++lastPoolId;

        poolInfos[newPoolId] = PoolInfo({
            startBlock: startBlock,
            endBlock: endBlock,
            rewardPerBlock: rewardPerBlock,
            poolToken: token,
            optionContract: optionContract,
            isActive: true
        });
        poolData[newPoolId] = PoolData({totalStakeAmount: 0, accuRewardPerShare: 0, accuRewardLastUpdateBlock: startBlock});

        emit PoolCreated(newPoolId, token, optionContract, startBlock, endBlock, rewardPerBlock);
    }

    /**
     * @notice Extends the end block of a pool
     * @dev The function will update the endBlock of a pool and emit a PoolEndBlockExtended event
     * @param poolId The ID of the pool
     * @param newEndBlock The new end block for the pool
     */
    function extendEndBlock(uint256 poolId, uint256 newEndBlock)
        external
        override
        onlyOwnerOrFactory
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        uint256 currentEndBlock = poolInfos[poolId].endBlock;
        require(newEndBlock > currentEndBlock, "StakingPools: end block not extended");

        poolInfos[poolId].endBlock = newEndBlock;

        emit PoolEndBlockExtended(poolId, currentEndBlock, newEndBlock);
    }

    /**
     * @notice Sets the per block reward for a pool
     * @dev The function will update the rewardPerBlock of a pool and emit a PoolRewardRateChanged event
     * @param poolId The ID of the pool
     * @param newRewardPerBlock The new reward per block for the pool
     */
    function setPoolReward(uint256 poolId, uint256 newRewardPerBlock)
        external
        onlyOwner
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        if (block.number >= poolInfos[poolId].startBlock) {
            // "Settle" rewards up to this block
            _updatePoolAccuReward(poolId);
        }

        // We're deliberately allowing setting the reward rate to 0 here. If it turns
        // out this, or even changing rates at all, is undesirable after deployment, the
        // ownership of this contract can be transferred to a contract incapable of making
        // calls to this function.
        uint256 currentRewardPerBlock = poolInfos[poolId].rewardPerBlock;
        poolInfos[poolId].rewardPerBlock = newRewardPerBlock;

        emit PoolRewardRateChanged(poolId, currentRewardPerBlock, newRewardPerBlock);
    }

    /**
     * @notice Sets the active status of a pool
     * @dev The function will update the isActive field of a pool and emit an IsActiveChanged event
     * @param poolId The ID of the pool
     * @param isActive The new active status for the pool
     */
    function setIsActive(uint256 poolId, bool isActive) external onlyOwner onlyPoolExists(poolId) {
        poolInfos[poolId].isActive = isActive;

        emit IsActiveChanged(poolId, isActive);
    }

    /**
     * @notice Sets the rewarder contract
     * @dev The function will update the rewarder field of the contract and emit a RewarderChanged event
     * @param newRewarder The address of the new rewarder contract
     */
    function setRewarder(address newRewarder) external onlyOwner {
        require(newRewarder != address(0), "StakingPools: zero address");

        address oldRewarder = address(rewarder);
        rewarder = IStakingPoolRewarder(newRewarder);

        emit RewarderChanged(oldRewarder, newRewarder);
    }

    /**
     * @notice Sets the factory contract
     * @dev The function will update the optionFactory field of the contract and emit a FactoryChanged event
     * @param newFactory The address of the new factory contract
     */
    function setFactory(address newFactory) external onlyOwner {
        require(newFactory != address(0), "StakingPools: zero address");

        address oldFactory = optionFactory;
        optionFactory = newFactory;

        emit FactoryChanged(oldFactory, optionFactory);
    }

    /**
     * @notice Allows a user to stake a certain amount in a specific pool
     * @dev Updates the pool's accumulated rewards and the user's reward, then stakes the specified amount.
     * @param poolId The ID of the pool
     * @param amount The amount to stake
     */
    function stake(uint256 poolId, uint256 amount) external onlyPoolExists(poolId) onlyPoolActive(poolId) {
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        _stake(poolId, msg.sender, amount);
    }

    /**
     * @notice Allows a user to unstake a certain amount from a specific pool
     * @dev Updates the pool's accumulated rewards and the user's reward, then unstakes the specified amount.
     * @param poolId The ID of the pool
     * @param amount The amount to unstake
     */
    function unstake(uint256 poolId, uint256 amount) external onlyPoolExists(poolId) {
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        _unstake(poolId, msg.sender, amount);
    }

    /**
     * @notice Allows an option contract to stake on behalf of a user in a specific pool
     * @dev Updates the pool's accumulated rewards and the user's reward, then stakes the specified amount. Additionally, updates the user's entry time and vests any pending rewards.
     * @param poolId The ID of the pool
     * @param amount The amount to stake
     * @param user The address of the user
     */
    function stakeFor(
        uint256 poolId,
        uint256 amount,
        address user
    ) external override onlyPoolExists(poolId) onlyPoolActive(poolId) onlyOptionContract(poolId) {
        require(user != address(0), "StakingPools: zero address");

        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, user);

        require(amount > 0, "StakingPools: cannot stake zero amount");

        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.add(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.add(amount);

        _vestPendingRewards(poolId, user);
        userData[poolId][user].entryTime = block.timestamp;

        emit Staked(poolId, user, poolInfos[poolId].poolToken, amount);
    }

    /**
     * @notice Allows an option contract to unstake on behalf of a user from a specific pool
     * @dev Updates the pool's accumulated rewards and the user's reward, then unstakes the specified amount. Transfers the unstaked tokens back to the user.
     * @param poolId The ID of the pool
     * @param amount The amount to unstake
     * @param user The address of the user
     */
    function unstakeFor(
        uint256 poolId,
        uint256 amount,
        address user
    ) external override onlyPoolExists(poolId) onlyOptionContract(poolId) {
        require(user != address(0), "StakingPools: zero address");

        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, user);

        require(amount > 0, "StakingPools: cannot unstake zero amount");

        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.sub(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.sub(amount);

        safeTransfer(poolInfos[poolId].poolToken, user, amount);

        emit Unstaked(poolId, user, poolInfos[poolId].poolToken, amount);
    }

    /**
     * @notice Allows a user to emergency unstake all staked tokens from a specific pool
     * @dev Unstakes all staked tokens and forfeits any pending rewards to prevent abuse. This function can be used when the user wants to quickly withdraw all staked tokens without claiming the rewards.
     * @param poolId The ID of the pool
     */
    function emergencyUnstake(uint256 poolId) external onlyPoolExists(poolId) {
        _unstake(poolId, msg.sender, userData[poolId][msg.sender].stakeAmount);

        userData[poolId][msg.sender].pendingReward = 0;
    }

    /**
     * @notice Allows a user to redeem rewards from a specific pool
     * @dev Calls the _redeemRewardsByAddress private function with the caller's address to claim rewards from the pool.
     * @param poolId The ID of the pool
     */
    function redeemRewards(uint256 poolId) external {
        _redeemRewardsByAddress(poolId, msg.sender);
    }

    /**
     * @notice Allows a user to redeem rewards from a list of pools
     * @dev Calls the _redeemRewardsByAddress private function for each pool in the list to claim rewards from the pools.
     * @param poolIds An array of the pool IDs
     */
    function redeemRewardsByList(uint256[] memory poolIds) external {
        for (uint256 i = 0; i < poolIds.length; i++) {
            _redeemRewardsByAddress(poolIds[i], msg.sender);
        }
    }

    /**
     * @notice Allows to redeem rewards from a specific pool for a specific user
     * @dev Calls the _redeemRewardsByAddress private function with the specified user address to claim rewards from the pool.
     * @param poolId The ID of the pool
     * @param user The address of the user
     */
    function redeemRewardsByAddress(uint256 poolId, address user) external override {
        _redeemRewardsByAddress(poolId, user);
    }

    /**
     * @notice Allows a user to unstake a certain amount from a specific pool and redeem the rewards
     * @dev Updates the pool's accumulated rewards and the user's reward, then unstakes the specified amount. Afterwards, redeems the rewards for the user.
     * @param poolId The ID of the pool
     * @param amount The amount to unstake
     */
    function unstakeAndRedeemReward(uint256 poolId, uint256 amount) external {
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        _unstake(poolId, msg.sender, amount);

        _redeemRewardsByAddress(poolId, msg.sender);
    }

    /**
     * @notice Redeems the rewards for a user in a specific pool
     * @dev Updates the pool's and the user's rewards, checks that the rewarder is set, vests any pending rewards and claims vested rewards for the user.
     * @param poolId The ID of the pool
     * @param user The address of the user
     */
    function _redeemRewardsByAddress(uint256 poolId, address user) private onlyPoolExists(poolId) {
        require(user != address(0), "StakingPools: zero address");

        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, user);

        require(address(rewarder) != address(0), "StakingPools: rewarder not set");

        _vestPendingRewards(poolId, user);

        uint256 claimed = rewarder.claimVestedReward(poolId, user);

        emit RewardRedeemed(poolId, user, address(rewarder), claimed);
    }

    /**
     * @notice Vests the pending rewards for a user in a specific pool
     * @dev Resets the user's pending reward to zero and transfers them to the rewarder contract, specifying the user's entry time.
     * @param poolId The ID of the pool
     * @param user The address of the user
     */
    function _vestPendingRewards(uint256 poolId, address user) private onlyPoolExists(poolId) {
        uint256 rewardToVest = userData[poolId][user].pendingReward;
        userData[poolId][user].pendingReward = 0;
        rewarder.onReward(poolId, user, rewardToVest, userData[poolId][user].entryTime);
    }

    /**
     * @notice Allows a user to stake a certain amount in a specific pool
     * @dev Transfers the specified amount of the pool's token from the user to the contract, updates the user's stake amount, and resets the user's entry time.
     * @param poolId The ID of the pool
     * @param user The address of the user
     * @param amount The amount to stake
     */
    function _stake(
        uint256 poolId,
        address user,
        uint256 amount
    ) private {
        require(amount > 0, "StakingPools: cannot stake zero amount");

        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.add(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.add(amount);

        safeTransferFrom(poolInfos[poolId].poolToken, user, address(this), amount);

        _vestPendingRewards(poolId, user);
        userData[poolId][user].entryTime = block.timestamp;

        emit Staked(poolId, user, poolInfos[poolId].poolToken, amount);
    }

    /**
     * @notice Allows a user to unstake a certain amount from a specific pool
     * @dev Transfers the specified amount of the pool's token back to the user and updates the user's stake amount.
     * @param poolId The ID of the pool
     * @param user The address of the user
     * @param amount The amount to unstake
     */
    function _unstake(
        uint256 poolId,
        address user,
        uint256 amount
    ) private {
        require(amount > 0, "StakingPools: cannot unstake zero amount");

        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.sub(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.sub(amount);

        safeTransfer(poolInfos[poolId].poolToken, user, amount);

        emit Unstaked(poolId, user, poolInfos[poolId].poolToken, amount);
    }

    /**
     * @notice Updates the accumulated reward per share for a specific pool
     * @dev If there has been more than one block since the last update and the total staked amount is positive, the accumulated reward per share is increased based on the number of blocks since the last update and the pool's reward per block.
     * @param poolId The ID of the pool
     */
    function _updatePoolAccuReward(uint256 poolId) private {
        PoolInfo storage currentPoolInfo = poolInfos[poolId];
        PoolData storage currentPoolData = poolData[poolId];

        uint256 appliedUpdateBlock = MathUpgradeable.min(block.number, currentPoolInfo.endBlock);
        uint256 durationInBlocks = appliedUpdateBlock.sub(currentPoolData.accuRewardLastUpdateBlock);

        if (durationInBlocks > 0) {
            if (currentPoolData.totalStakeAmount > 0) {
                currentPoolData.accuRewardPerShare = currentPoolData.accuRewardPerShare.add(
                    durationInBlocks.mul(currentPoolInfo.rewardPerBlock).mul(ACCU_REWARD_MULTIPLIER).div(
                        currentPoolData.totalStakeAmount
                    )
                );
            }
            currentPoolData.accuRewardLastUpdateBlock = appliedUpdateBlock;
        }
    }

    /**
     * @notice Updates the pending reward and entry accumulated reward per share for a staker in a specific pool
     * @dev If the pool's accumulated reward per share has increased since the staker's entry, the staker's pending reward is increased based on their stake amount and the difference in accumulated reward per share, and their entry accumulated reward per share is updated.
     * @param poolId The ID of the pool
     * @param staker The address of the staker
     */
    function _updateStakerReward(uint256 poolId, address staker) private {
        UserData storage currentUserData = userData[poolId][staker];
        PoolData storage currentPoolData = poolData[poolId];

        uint256 stakeAmount = currentUserData.stakeAmount;
        uint256 stakerEntryRate = currentUserData.entryAccuRewardPerShare;
        uint256 accuDifference = currentPoolData.accuRewardPerShare.sub(stakerEntryRate);

        if (accuDifference > 0) {
            currentUserData.pendingReward = currentUserData.pendingReward.add(
                stakeAmount.mul(accuDifference).div(ACCU_REWARD_MULTIPLIER)
            );
            currentUserData.entryAccuRewardPerShare = currentPoolData.accuRewardPerShare;
        }
    }

    /**
     * @notice Allows the contract to approve the transfer of a certain amount of a token on behalf of the contract
     * @dev Calls the approve function of the token contract with the specified spender and amount, and requires that the call was successful.
     * @param token The address of the token contract
     * @param spender The address of the spender
     * @param amount The amount to approve
     */
    function safeApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE_SELECTOR, spender, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: approve failed");
    }

    /**
     * @notice Allows the contract to transfer a certain amount of a token to a recipient
     * @dev Calls the transfer function of the token contract with the specified recipient and amount, and requires that the call was successful.
     * @param token The address of the token contract
     * @param recipient The address of the recipient
     * @param amount The amount to transfer
     */
    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: transfer failed");
    }

    /**
     * @notice Allows the contract to transfer a certain amount of a token from a sender to a recipient
     * @dev Calls the transferFrom function of the token contract with the specified sender, recipient, and amount, and requires that the call was successful.
     * @param token The address of the token contract
     * @param sender The address of the sender
     * @param recipient The address of the recipient
     * @param amount The amount to transfer
     */
    function safeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFERFROM_SELECTOR, sender, recipient, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: transferFrom failed");
    }
}