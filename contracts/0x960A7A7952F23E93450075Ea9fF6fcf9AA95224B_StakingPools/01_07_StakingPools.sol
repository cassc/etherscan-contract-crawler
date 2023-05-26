// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IStakingPoolMigrator.sol";
import "./interfaces/IStakingPoolRewarder.sol";

/**
 * @title StakingPools
 *
 * @dev A contract for staking Uniswap LP tokens in exchange for locked CONV rewards.
 * No actual CONV tokens will be held or distributed by this contract. Only the amounts
 * are accumulated.
 *
 * @dev The `migrator` in this contract has access to users' staked tokens. Any changes
 * to the migrator address will only take effect after a delay period specified at contract
 * creation.
 *
 * @dev This contract interacts with token contracts via `safeApprove`, `safeTransfer`,
 * and `safeTransferFrom` instead of the standard Solidity interface so that some non-ERC20-
 * compatible tokens (e.g. Tether) can also be staked.
 */
contract StakingPools is Ownable {
    using SafeMath for uint256;

    event PoolCreated(
        uint256 indexed poolId,
        address indexed token,
        uint256 startBlock,
        uint256 endBlock,
        uint256 migrationBlock,
        uint256 rewardPerBlock
    );
    event PoolEndBlockExtended(uint256 indexed poolId, uint256 oldEndBlock, uint256 newEndBlock);
    event PoolMigrationBlockExtended(uint256 indexed poolId, uint256 oldMigrationBlock, uint256 newMigrationBlock);
    event PoolRewardRateChanged(uint256 indexed poolId, uint256 oldRewardPerBlock, uint256 newRewardPerBlock);
    event MigratorChangeProposed(address newMigrator);
    event MigratorChanged(address oldMigrator, address newMigrator);
    event RewarderChanged(address oldRewarder, address newRewarder);
    event PoolMigrated(uint256 indexed poolId, address oldToken, address newToken);
    event Staked(uint256 indexed poolId, address indexed staker, address token, uint256 amount);
    event Unstaked(uint256 indexed poolId, address indexed staker, address token, uint256 amount);
    event RewardRedeemed(uint256 indexed poolId, address indexed staker, address rewarder, uint256 amount);

    /**
     * @param startBlock the block from which reward accumulation starts
     * @param endBlock the block from which reward accumulation stops
     * @param migrationBlock the block since which LP token migration can be triggered
     * @param rewardPerBlock total amount of token to be rewarded in a block
     * @param poolToken token to be staked
     */
    struct PoolInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 migrationBlock;
        uint256 rewardPerBlock;
        address poolToken;
    }
    /**
     * @param totalStakeAmount total amount of staked tokens
     * @param accuRewardPerShare accumulated rewards for a single unit of token staked, multiplied by `ACCU_REWARD_MULTIPLIER`
     * @param accuRewardLastUpdateBlock the block number at which the `accuRewardPerShare` field was last updated
     */
    struct PoolData {
        uint256 totalStakeAmount;
        uint256 accuRewardPerShare;
        uint256 accuRewardLastUpdateBlock;
    }
    /**
     * @param stakeAmount amount of token the user stakes
     * @param pendingReward amount of reward to be redeemed by the user up to the user's last action
     * @param entryAccuRewardPerShare the `accuRewardPerShare` value at the user's last stake/unstake action
     */
    struct UserData {
        uint256 stakeAmount;
        uint256 pendingReward;
        uint256 entryAccuRewardPerShare;
    }
    /**
     * @param proposeTime timestamp when the change is proposed
     * @param newMigrator new migrator address
     */
    struct PendingMigratorChange {
        uint64 proposeTime;
        address newMigrator;
    }

    uint256 public lastPoolId; // The first pool has ID of 1

    IStakingPoolMigrator public migrator;
    uint256 public migratorSetterDelay;
    PendingMigratorChange public pendingMigrator;

    IStakingPoolRewarder public rewarder;

    mapping(uint256 => PoolInfo) public poolInfos;
    mapping(uint256 => PoolData) public poolData;
    mapping(uint256 => mapping(address => UserData)) public userData;

    uint256 private constant ACCU_REWARD_MULTIPLIER = 10**20; // Precision loss prevention

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));
    bytes4 private constant TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    modifier onlyPoolExists(uint256 poolId) {
        require(poolInfos[poolId].endBlock > 0, "StakingPools: pool not found");
        _;
    }

    modifier onlyPoolActive(uint256 poolId) {
        require(
            block.number >= poolInfos[poolId].startBlock && block.number < poolInfos[poolId].endBlock,
            "StakingPools: pool not active"
        );
        _;
    }

    modifier onlyPoolNotEnded(uint256 poolId) {
        require(block.number < poolInfos[poolId].endBlock, "StakingPools: pool ended");
        _;
    }

    function getReward(uint256 poolId, address staker) external view returns (uint256) {
        UserData memory currentUserData = userData[poolId][staker];
        PoolInfo memory currentPoolInfo = poolInfos[poolId];
        PoolData memory currentPoolData = poolData[poolId];

        uint256 latestAccuRewardPerShare =
            currentPoolData.totalStakeAmount > 0
                ? currentPoolData.accuRewardPerShare.add(
                    Math
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

    constructor(uint256 _migratorSetterDelay) {
        require(_migratorSetterDelay > 0, "StakingPools: zero setter delay");

        migratorSetterDelay = _migratorSetterDelay;
    }

    function createPool(
        address token,
        uint256 startBlock,
        uint256 endBlock,
        uint256 migrationBlock,
        uint256 rewardPerBlock
    ) external onlyOwner {
        require(token != address(0), "StakingPools: zero address");
        require(
            startBlock > block.number && endBlock > startBlock && migrationBlock > startBlock,
            "StakingPools: invalid block range"
        );
        require(rewardPerBlock > 0, "StakingPools: reward must be positive");

        uint256 newPoolId = ++lastPoolId;

        poolInfos[newPoolId] = PoolInfo({
            startBlock: startBlock,
            endBlock: endBlock,
            migrationBlock: migrationBlock,
            rewardPerBlock: rewardPerBlock,
            poolToken: token
        });
        poolData[newPoolId] = PoolData({totalStakeAmount: 0, accuRewardPerShare: 0, accuRewardLastUpdateBlock: startBlock});

        emit PoolCreated(newPoolId, token, startBlock, endBlock, migrationBlock, rewardPerBlock);
    }

    function extendEndBlock(uint256 poolId, uint256 newEndBlock)
        external
        onlyOwner
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        uint256 currentEndBlock = poolInfos[poolId].endBlock;
        require(newEndBlock > currentEndBlock, "StakingPools: end block not extended");

        poolInfos[poolId].endBlock = newEndBlock;

        emit PoolEndBlockExtended(poolId, currentEndBlock, newEndBlock);
    }

    function extendMigrationBlock(uint256 poolId, uint256 newMigrationBlock)
        external
        onlyOwner
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        uint256 currentMigrationBlock = poolInfos[poolId].migrationBlock;
        require(newMigrationBlock > currentMigrationBlock, "StakingPools: migration block not extended");

        poolInfos[poolId].migrationBlock = newMigrationBlock;

        emit PoolMigrationBlockExtended(poolId, currentMigrationBlock, newMigrationBlock);
    }

    function setPoolReward(uint256 poolId, uint256 newRewardPerBlock)
        external
        onlyOwner
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        if ( block.number >= poolInfos[poolId].startBlock) {
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

    function proposeMigratorChange(address newMigrator) external onlyOwner {
        pendingMigrator = PendingMigratorChange({proposeTime: uint64(block.timestamp), newMigrator: newMigrator});

        emit MigratorChangeProposed(newMigrator);
    }

    function executeMigratorChange() external {
        require(pendingMigrator.proposeTime > 0, "StakingPools: migrator change proposal not found");
        require(
            block.timestamp >= uint256(pendingMigrator.proposeTime).add(migratorSetterDelay),
            "StakingPools: migrator setter delay not passed"
        );

        address oldMigrator = address(migrator);
        migrator = IStakingPoolMigrator(pendingMigrator.newMigrator);

        // Clear storage
        pendingMigrator = PendingMigratorChange({proposeTime: 0, newMigrator: address(0)});

        emit MigratorChanged(oldMigrator, address(migrator));
    }

    function setRewarder(address newRewarder) external onlyOwner {
        address oldRewarder = address(rewarder);
        rewarder = IStakingPoolRewarder(newRewarder);

        emit RewarderChanged(oldRewarder, newRewarder);
    }

    function migratePool(uint256 poolId) external onlyPoolExists(poolId) {
        require(address(migrator) != address(0), "StakingPools: migrator not set");

        PoolInfo memory currentPoolInfo = poolInfos[poolId];
        PoolData memory currentPoolData = poolData[poolId];
        require(block.number >= currentPoolInfo.migrationBlock, "StakingPools: migration block not reached");

        safeApprove(currentPoolInfo.poolToken, address(migrator), currentPoolData.totalStakeAmount);

        // New token balance is not validated here since the migrator can do whatever
        // it wants anyways (including providing a fake token address with fake balance).
        // It's the migrator contract's responsibility to ensure tokens are properly migrated.
        address newToken =
            migrator.migrate(poolId, address(currentPoolInfo.poolToken), uint256(currentPoolData.totalStakeAmount));
        require(newToken != address(0), "StakingPools: zero new token address");

        poolInfos[poolId].poolToken = newToken;

        emit PoolMigrated(poolId, currentPoolInfo.poolToken, newToken);
    }

    function stake(uint256 poolId, uint256 amount) external onlyPoolExists(poolId) onlyPoolActive(poolId) {
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        _stake(poolId, msg.sender, amount);
    }

    function unstake(uint256 poolId, uint256 amount) external onlyPoolExists(poolId) {
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        _unstake(poolId, msg.sender, amount);
    }

    function emergencyUnstake(uint256 poolId) external onlyPoolExists(poolId) {
        _unstake(poolId, msg.sender, userData[poolId][msg.sender].stakeAmount);

        // Forfeit user rewards to avoid abuse
        userData[poolId][msg.sender].pendingReward = 0;
    }

    function redeemRewards(uint256 poolId) external onlyPoolExists(poolId) {

        redeemRewardsByAddress(poolId, msg.sender);
    }

    function redeemRewardsByAddress(uint256 poolId, address user) public onlyPoolExists(poolId) {

        require(user != address(0), "StakingPools: zero address");

        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, user);

        require(address(rewarder) != address(0), "StakingPools: rewarder not set");

        uint256 rewardToRedeem = userData[poolId][user].pendingReward;
        require(rewardToRedeem > 0, "StakingPools: no reward to redeem");

        userData[poolId][user].pendingReward = 0;

        rewarder.onReward(poolId, user, rewardToRedeem);

        emit RewardRedeemed(poolId, user, address(rewarder), rewardToRedeem);
    }

    function _stake(
        uint256 poolId,
        address user,
        uint256 amount
    ) private {
        require(amount > 0, "StakingPools: cannot stake zero amount");

        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.add(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.add(amount);

        safeTransferFrom(poolInfos[poolId].poolToken, user, address(this), amount);

        emit Staked(poolId, user, poolInfos[poolId].poolToken, amount);
    }

    function _unstake(
        uint256 poolId,
        address user,
        uint256 amount
    ) private {
        require(amount > 0, "StakingPools: cannot unstake zero amount");

        // No sufficiency check required as sub() will throw anyways
        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.sub(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.sub(amount);

        safeTransfer(poolInfos[poolId].poolToken, user, amount);

        emit Unstaked(poolId, user, poolInfos[poolId].poolToken, amount);
    }

    function _updatePoolAccuReward(uint256 poolId) private {
        PoolInfo storage currentPoolInfo = poolInfos[poolId];
        PoolData storage currentPoolData = poolData[poolId];

        uint256 appliedUpdateBlock = Math.min(block.number, currentPoolInfo.endBlock);
        uint256 durationInBlocks = appliedUpdateBlock.sub(currentPoolData.accuRewardLastUpdateBlock);

        // This saves tx cost when being called multiple times in the same block
        if (durationInBlocks > 0) {
            // No need to update the rate if no one staked at all
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

    function safeApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE_SELECTOR, spender, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: approve failed");
    }

    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, sender, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: transferFrom failed");
    }
}