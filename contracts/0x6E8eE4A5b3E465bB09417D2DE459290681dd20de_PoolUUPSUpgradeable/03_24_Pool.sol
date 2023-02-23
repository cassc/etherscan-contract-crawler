// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IYieldFarmingV1Staking.sol";
import "./interfaces/IYieldFarmingV1Pool.sol";

contract Pool is IYieldFarmingV1Pool, Initializable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // important: never change the order, type or remove variables
    // it's safe only to add new variables at the end to avoid any storage bugs

    TokenDetails[] public poolTokens;
    uint8 public maxDecimals;

    IERC20Upgradeable public rewardToken;

    address public rewardsEscrow;
    IYieldFarmingV1Staking public staking;

    uint256 public totalDistributedAmount;
    uint128 public numberOfEpochs;
    uint128 public epochsDelayedFromStakingContract;

    uint256 public totalAmountPerEpoch;
    uint128 public stoppedAtEpoch; // 0 by default; any value > 0 means that the pool is stopped

    struct PoolSize {
        bool exists;
        uint256 value;
    }

    mapping(uint128 => PoolSize) public epochPoolSizeCache;

    mapping(address => uint128) public userLastEpochIdHarvested;

    uint256 public epochDuration; // init from staking contract
    uint256 public epoch1Start; // init from staking contract

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(PoolConfig memory cfg, address roleAdmin) public initializer {
        __Pool_init(cfg, roleAdmin);
    }

    function __Pool_init(PoolConfig memory cfg, address roleAdmin) internal onlyInitializing {
        __AccessControl_init();

        __Pool_init_unchained(cfg, roleAdmin);
    }

    function __Pool_init_unchained(PoolConfig memory cfg, address roleAdmin) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
        _grantRole(MANAGER_ROLE, roleAdmin);

        for (uint256 i = 0; i < cfg.poolTokenAddresses.length; i++) {
            address addr = cfg.poolTokenAddresses[i];
            require(addr != address(0), "Pool: invalid pool token address");

            uint8 decimals = IERC20MetadataUpgradeable(addr).decimals();
            poolTokens.push(TokenDetails(addr, decimals));

            if (maxDecimals < decimals) {
                maxDecimals = decimals;
            }
        }

        rewardToken = IERC20Upgradeable(cfg.rewardTokenAddress);

        staking = IYieldFarmingV1Staking(cfg.stakingAddress);
        rewardsEscrow = cfg.rewardsEscrowAddress;

        totalDistributedAmount = cfg.totalDistributedAmount;
        numberOfEpochs = cfg.numberOfEpochs;
        epochsDelayedFromStakingContract = cfg.epochsDelayedFromStaking;

        epochDuration = staking.epochDuration();
        epoch1Start = staking.epoch1Start() + epochDuration * cfg.epochsDelayedFromStaking;

        totalAmountPerEpoch = cfg.totalDistributedAmount / cfg.numberOfEpochs;
    }

    // public methods

    function stopAtEpoch(uint128 epochId) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "Pool: only managers can stop the pool");
        require(epochId <= numberOfEpochs, "Pool: invalid epochId");
        require(epochId >= getCurrentEpoch(), "Pool: invalid epochId");

        stoppedAtEpoch = epochId;
    }

    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256){
        uint128 currentEpoch = getCurrentEpoch();

        // noting to claim before epoch 2
        require(currentEpoch > 1, "Pool: too soon");

        uint128 lastClaimableEpoch = currentEpoch - 1;

        // force max number of epochs
        if (lastClaimableEpoch > numberOfEpochs) {
            lastClaimableEpoch = numberOfEpochs;
        }

        if (stoppedAtEpoch > 0 && lastClaimableEpoch > stoppedAtEpoch) {
            lastClaimableEpoch = stoppedAtEpoch;
        }

        uint128 userLastEpochHarvested = userLastEpochIdHarvested[msg.sender];

        uint256 totalUserReward;
        for (uint128 i = userLastEpochHarvested + 1; i <= lastClaimableEpoch; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalUserReward += _harvest(i);
        }

        emit MassHarvest(msg.sender, lastClaimableEpoch - userLastEpochHarvested, totalUserReward);

        if (totalUserReward > 0) {
            rewardToken.safeTransferFrom(rewardsEscrow, msg.sender, totalUserReward);
        }

        return totalUserReward;
    }

    function harvest(uint128 epochId) external returns (uint256){
        if (stoppedAtEpoch > 0) {
            require(epochId <= stoppedAtEpoch, "Pool: invalid epochId");
        }
        require(getCurrentEpoch() > epochId, "Pool: invalid epochId");
        require(epochId <= numberOfEpochs, "Pool: invalid epochId");
        require(userLastEpochIdHarvested[msg.sender] + 1 == epochId, "Pool: harvest in order");

        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            rewardToken.safeTransferFrom(rewardsEscrow, msg.sender, userReward);
        }

        emit Harvest(msg.sender, epochId, userReward);

        return userReward;
    }

    // views

    function getClaimableAmount(address account) external view returns (uint256) {
        uint256 claimable = 0;

        uint128 currentEpoch = getCurrentEpoch();
        if (currentEpoch < 2) {
            return 0;
        }

        uint128 lastClaimableEpoch = currentEpoch - 1;

        // force max number of epochs
        if (lastClaimableEpoch > numberOfEpochs) {
            lastClaimableEpoch = numberOfEpochs;
        }

        if (stoppedAtEpoch > 0 && lastClaimableEpoch > stoppedAtEpoch) {
            lastClaimableEpoch = stoppedAtEpoch;
        }

        for (uint128 i = userLastEpochIdHarvested[account] + 1; i <= lastClaimableEpoch; i ++) {
            uint256 epochPoolSize = getEpochPoolSize(i);
            uint256 epochAccountStake = getEpochUserBalance(account, i);

            if (epochPoolSize == 0 || epochAccountStake == 0) {
                continue;
            }

            claimable += totalAmountPerEpoch * epochAccountStake / epochPoolSize;
        }

        return claimable;
    }

    // get the staking epoch
    function getEpochOnStaking(uint128 epochId) public view returns (uint128) {
        return epochId + epochsDelayedFromStakingContract;
    }

    function getCurrentEpoch() public view returns (uint128) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return uint128(
            (block.timestamp - epoch1Start) / epochDuration + 1
        );
    }

    // calls to the staking smart contract to retrieve the epoch total pool size
    function getEpochPoolSize(uint128 epochId) public view returns (uint256) {
        uint128 stakingEpochId = getEpochOnStaking(epochId);

        uint256 totalPoolSize;

        for (uint256 i = 0; i < poolTokens.length; i++) {
            uint256 poolSize = staking.getEpochPoolSize(poolTokens[i].addr, stakingEpochId);
            totalPoolSize = totalPoolSize + poolSize * 10 ** (maxDecimals - poolTokens[i].decimals);
        }

        return totalPoolSize;
    }

    function getEpochPoolSizeByToken(address token, uint128 epochId) public view returns (uint256) {
        uint128 stakingEpochId = getEpochOnStaking(epochId);

        return staking.getEpochPoolSize(token, stakingEpochId);
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochUserBalance(address userAddress, uint128 epochId) public view returns (uint256) {
        uint128 stakingEpochId = getEpochOnStaking(epochId);

        uint256 totalUserBalance;
        for (uint256 i = 0; i < poolTokens.length; i++) {
            uint256 userBalance = staking.getEpochUserBalance(userAddress, poolTokens[i].addr, stakingEpochId);
            totalUserBalance = totalUserBalance + userBalance * 10 ** (maxDecimals - poolTokens[i].decimals);
        }

        return totalUserBalance;
    }

    function getEpochUserBalanceByToken(address userAddress, address token, uint128 epochId) public view returns (uint256) {
        uint128 stakingEpochId = getEpochOnStaking(epochId);

        return staking.getEpochUserBalance(userAddress, token, stakingEpochId);
    }

    function getPoolTokens() external view returns (address[] memory tokens) {
        tokens = new address[](poolTokens.length);

        for (uint256 i = 0; i < poolTokens.length; i++) {
            tokens[i] = poolTokens[i].addr;
        }
    }

    // internal methods

    function _initEpoch(uint128 epochId) internal {
        if (epochPoolSizeCache[epochId].exists) {
            return;
        }

        epochPoolSizeCache[epochId] = PoolSize(true, getEpochPoolSize(epochId));
    }

    function _harvest(uint128 epochId) internal returns (uint256) {
        _initEpoch(epochId);

        // Set user last harvested epoch
        userLastEpochIdHarvested[msg.sender] = epochId;

        // exit if there is no stake on the epoch
        if (epochPoolSizeCache[epochId].value == 0) {
            return 0;
        }

        uint256 userBalance = getEpochUserBalance(msg.sender, epochId);
        uint256 poolSize = epochPoolSizeCache[epochId].value;

        return totalAmountPerEpoch * userBalance / poolSize;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}