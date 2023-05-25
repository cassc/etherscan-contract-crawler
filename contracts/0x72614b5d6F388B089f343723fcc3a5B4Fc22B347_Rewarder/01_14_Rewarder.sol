// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IRewarder } from "./interfaces/IRewarder.sol";
import { IRewarderVault } from "./interfaces/IRewarderVault.sol";
import { IMasterMind } from "./interfaces/IMasterMind.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Rewarder is IRewarder, Ownable {
    using SafeERC20 for IERC20;

    bool private _migrated;
    IERC20 public immutable rewardToken;
    IMasterMind public immutable masterMind;
    IRewarderVault public immutable rewarderVault;

    mapping (uint256 => PoolInfo) public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 private MAX_REWARD_PER_BLOCK_PER_POOL = 100e18;

    address public dev;
    address public dao;
    uint256 public constant FEE_BASE = 1000;
    uint256 public devFee = 100;
    uint256 public daoFee = 100;
    uint256 public devDebt;
    uint256 public daoDebt;

    constructor (IERC20 _rewardToken, IMasterMind _masterMind, IRewarderVault _rewarderVault, address _dao) {
        require(address(_rewardToken) != address(0) && address(_masterMind) != address(0) && address(_rewarderVault) != address(0), "Wrong Init");
        rewardToken = _rewardToken;
        masterMind = _masterMind;
        rewarderVault = _rewarderVault;
        dev = msg.sender;
        dao = _dao;
    }

    modifier onlyMM {
        require(
            msg.sender == address(masterMind),
            "Only MM can call this function."
        );
        _;
    }

    function setDevFee(uint256 value_) external onlyOwner {
        require(value_ <= 350, 'too much');
        devFee = value_;
    }

    function setDaoFee(uint256 value_) external onlyOwner {
        require(value_ <= 350, 'too much');
        daoFee = value_;
    }

    function updateMaxRewardPerBlockPerPool(uint256 amount_) external onlyOwner {
        MAX_REWARD_PER_BLOCK_PER_POOL = amount_;
    }

    struct UserMigration {
        address address_;
        UserInfo info;
    }

    struct MigrationPackage {
        uint256 poolId;
        PoolInfo poolInfo;
        UserMigration[] users;
    }

    function migrate(MigrationPackage[] calldata packs) external onlyOwner {
        require(!_migrated);
        uint256 l = packs.length;
        for (uint256 i; i < l;){
            MigrationPackage memory pack = packs[i];
            uint256 poolId = pack.poolId;
            poolInfo[poolId] = pack.poolInfo;
            uint256 ul = pack.users.length;
            for (uint256 j; j < ul;) {
                UserMigration memory user = pack.users[j];
                userInfo[poolId][user.address_] = user.info;
            unchecked{ ++j; }
            }
        unchecked{ ++i; }
        }
        _migrated = true;
    }

    function updateUser(uint256 poolId, address userAddress, uint256 rewardableDeposit) external override onlyMM {
        (PoolInfo memory pool,) = updatePool(poolId);
        UserInfo storage user = userInfo[poolId][userAddress];
        assert(pool.lifetimeRewardPerOneEtherOfDeposit >= user.lifetimeRewardPerOneEtherOfDeposit);
        uint256 oneEtherOfDepositRewardAppreciation;
    unchecked {
        oneEtherOfDepositRewardAppreciation = pool.lifetimeRewardPerOneEtherOfDeposit - user.lifetimeRewardPerOneEtherOfDeposit;
    }
        if(oneEtherOfDepositRewardAppreciation > 0) {
            uint256 rewardAmount = oneEtherOfDepositRewardAppreciation * user.rewardableDeposit;
            user.pendingReward = user.pendingReward + (rewardAmount / 1 ether);
        }

        user.rewardableDeposit = rewardableDeposit;
        user.lifetimeRewardPerOneEtherOfDeposit = pool.lifetimeRewardPerOneEtherOfDeposit;
        emit UpdateUser(userAddress, poolId, rewardableDeposit);
    }

    function claim(uint256 poolId, address userAddress, address to) onlyMM override external {
        UserInfo storage user = userInfo[poolId][userAddress];
        uint256 rewardAmount = user.pendingReward;
        if(rewardAmount > 0) {
            user.pendingReward = 0;
            rewardToken.safeTransferFrom(address(rewarderVault), to, rewardAmount);
            devDebt += rewardAmount*devFee / FEE_BASE;
            daoDebt += rewardAmount*daoFee / FEE_BASE;
            emit Claim(userAddress, poolId, rewardAmount, to);
        }
    }

    /// @notice Returns the number of MM pools.
    function poolCount() public view override returns (uint256 pools) {
        pools = masterMind.poolCount();
    }

    function addBulk(uint256[] memory rewardsPerBlockPerOneEther, uint256[] memory poolIdList, uint256[] memory poolLimits) external override onlyOwner{
        for (uint i = 0; i < rewardsPerBlockPerOneEther.length; i++) {
            uint256 rewardPerBlockPerOneEther = rewardsPerBlockPerOneEther[i];
            uint256 poolId = poolIdList[i];
            require(poolInfo[poolId].lastRewardBlock == 0, "Pool already exists");
            poolInfo[poolId] = PoolInfo({
            rewardPerBlockPerOneEtherOfDeposit: rewardPerBlockPerOneEther,
            lastRewardBlock: block.number,
            lifetimeRewardPerOneEtherOfDeposit: 0,
            limitPerBlockPerOneEtherOfDeposit: poolLimits[i]
            });

            emit AddPool(poolId, rewardsPerBlockPerOneEther[i]);
        }
    }

    function updatePoolRewards(uint256 poolId, uint256 newRewardPerBlockPerEther) external override onlyOwner {
        _updatePoolRewards(poolId, newRewardPerBlockPerEther);
        emit UpdatePoolRewards(poolId, newRewardPerBlockPerEther);
    }

    function massUpdatePoolRewards(uint256[] memory poolIds, uint256[] memory newRewardsPerBlockPerEther) external override onlyOwner {
        require(poolIds.length == newRewardsPerBlockPerEther.length, "non-equal arr length");
        for (uint i = 0; i < poolIds.length; i++) {
            _updatePoolRewards(poolIds[i], newRewardsPerBlockPerEther[i]);
        }
        emit UpdatePoolsRewards(poolIds, newRewardsPerBlockPerEther);
    }

    function _updatePoolRewards(uint256 poolId, uint256 newRewardPerBlockPerEther) internal {
        (PoolInfo memory pool, uint256 rewardableDeposits) = updatePool(poolId);
        require(newRewardPerBlockPerEther < pool.limitPerBlockPerOneEtherOfDeposit &&
            rewardableDeposits * pool.limitPerBlockPerOneEtherOfDeposit < MAX_REWARD_PER_BLOCK_PER_POOL, "Rewards are too big.");
        pool.rewardPerBlockPerOneEtherOfDeposit = newRewardPerBlockPerEther;
        poolInfo[poolId] = pool;
    }

    function updatePoolLimit(uint256 poolId, uint256 newLimitPerBlockPerEther) external override onlyOwner {
        _updatePoolLimit(poolId, newLimitPerBlockPerEther);
    }

    function massUpdatePoolLimits(uint256[] memory poolIds, uint256[] memory newLimitsPerBlockPerEther) external override onlyOwner {
        require(poolIds.length == newLimitsPerBlockPerEther.length, "non-equal arr length");
        for (uint i = 0; i < poolIds.length; i++) {
            _updatePoolLimit(poolIds[i], newLimitsPerBlockPerEther[i]);
        }
    }

    function _updatePoolLimit(uint256 poolId, uint256 newLimitPerBlockPerEther) internal {
        poolInfo[poolId].limitPerBlockPerOneEtherOfDeposit = newLimitPerBlockPerEther;
        emit UpdatePoolLimit(poolId, newLimitPerBlockPerEther);
    }

    function pendingReward(uint256 poolId, address userAddress) external view override returns (uint256 _pendingReward) {
        PoolInfo memory pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][userAddress];
        _pendingReward = user.pendingReward;
        uint256 lifetimeRewardPerOneEtherOfDeposit = pool.lifetimeRewardPerOneEtherOfDeposit;
        if (block.number > pool.lastRewardBlock) {
            uint256 rewardableDeposits = masterMind.poolInfo(poolId).rewardableDeposits;
            if (rewardableDeposits > 0) {
                uint256 blocks = uint256(block.number - pool.lastRewardBlock);
                uint256 rewardPerOneEtherOfDeposit = blocks * poolInfo[poolId].rewardPerBlockPerOneEtherOfDeposit;
                lifetimeRewardPerOneEtherOfDeposit = lifetimeRewardPerOneEtherOfDeposit + rewardPerOneEtherOfDeposit;
            }
        }

        uint256 oneEtherOfDepositRewardAppreciation = lifetimeRewardPerOneEtherOfDeposit - user.lifetimeRewardPerOneEtherOfDeposit;
        if(oneEtherOfDepositRewardAppreciation > 0) {
            uint256 rewardAmount = oneEtherOfDepositRewardAppreciation * user.rewardableDeposit;
            _pendingReward = _pendingReward + (rewardAmount / 1 ether);
        }
    }

    function massUpdatePools(uint256[] calldata poolIdList) external override {
        for (uint256 i = 0; i < poolIdList.length; ++i) {
            updatePool(poolIdList[i]);
        }
    }

    function updatePool(uint256 poolId) public override returns (PoolInfo memory pool, uint256 rewardableDeposits) {
        pool = poolInfo[poolId];
        require(pool.lastRewardBlock != 0, "Pool does not exist");
        rewardableDeposits = masterMind.poolInfo(poolId).rewardableDeposits;
        if (block.number > pool.lastRewardBlock) {
            if (rewardableDeposits > 0) {
                uint256 rewardPerOneEtherOfDeposit = uint256(block.number - pool.lastRewardBlock) * pool.rewardPerBlockPerOneEtherOfDeposit;
                pool.lifetimeRewardPerOneEtherOfDeposit = pool.lifetimeRewardPerOneEtherOfDeposit + rewardPerOneEtherOfDeposit;
            }
            pool.lastRewardBlock = block.number;
            poolInfo[poolId] = pool;
            emit UpdatePool(poolId, pool.lastRewardBlock, rewardableDeposits, pool.lifetimeRewardPerOneEtherOfDeposit);
        }
    }

    function distributeFee() external override {
        require(msg.sender == dev || msg.sender == dao || msg.sender == owner(), "You can't do it");
        uint256 _devDebt = devDebt;
        uint256 _daoDebt = daoDebt;
        daoDebt = 0;
        devDebt = 0;
        rewardToken.safeTransferFrom(address(rewarderVault), dev, _devDebt);
        rewardToken.safeTransferFrom(address(rewarderVault), dao, _daoDebt);
    }

    function updateDev(address newDev) external override onlyOwner {
        dev = newDev;
        emit UpdateDev(newDev);
    }

    function updateDao(address newDao) external override onlyOwner {
        dao = newDao;
        emit UpdateDao(newDao);
    }
}