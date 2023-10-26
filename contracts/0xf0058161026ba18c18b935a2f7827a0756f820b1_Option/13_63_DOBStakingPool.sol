// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IStakingPoolRewarder.sol";
import "../interfaces/IDOBStakingPool.sol";
import "../interfaces/IOption.sol";
import "../interfaces/ITokenKeeper.sol";

/**
 * @title DOBStakingPool
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice The DOBStakingPool contract manages staking and reward distribution for $DOB tokens.
 * @dev It includes functionalities for staking $DOB, claiming rewards, withdrawing and updating parameters.
 */
contract DOBStakingPool is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IDOBStakingPool {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Address of the DOB token.
     * @dev This is the token that will be staked in the pool.
     */
    address public DOB;

    /**
     * @notice Address where the fees are collected.
     * @dev This is generally a multisig wallet or a treasury account.
     */
    address public feeCollector;

    /**
     * @notice Address where bullets are collected.
     * @dev Bullets are a secondary token used in the ecosystem.
     */
    address public bulletCollector;

    /**
     * @notice Address of the reward dispatcher.
     * @dev This address is responsible for calculating and distributing rewards.
     */
    address public rewardDispatcher;

    /**
     * @notice Address of the worker.
     * @dev This address performs certain actions that are restricted to workers.
     */
    address public worker;

    /**
     * @notice Address of the OptionFactory contract.
     * @dev This is the contract responsible for creating and managing options.
     */
    address public optionFactory;

    /**
     * @notice Address of the uHODL contract.
     * @dev This is one of the contracts that will receive rewards.
     */
    address public uHODL;

    /**
     * @notice Address of the bHODL contract.
     * @dev This is one of the contracts that will receive rewards.
     */
    address public bHODL;

    /**
     * @notice Array of all activated options.
     * @dev Each option includes an optionAddress, bullet, sniper and bulletBalance.
     */
    OptionData[] public activatedOptions;

    /**
     * @notice The bullet reward threshold.
     * @dev Users with a daily stake more than this threshold will receive bullet rewards.
     */
    uint256 public bulletRewardThreshold;

    /**
     * @notice The extension of lock days.
     * @dev This value affects the duration of staking.
     */
    uint256 public extendLockDays;

    /**
     * @notice The timestamp of the last work action performed.
     * @dev This can be used for tracking purposes and for enforcing time-based conditions.
     */
    uint256 public lastWorkTimestamp;

    /**
     * @notice A flag indicating whether the contract should check for an NFT.
     * @dev If set to true, the contract will check for the presence of an NFT during certain actions.
     */
    bool public isCheckNFT;

    /**
     * @notice The address of the NFT contract.
     * @dev This is the contract that manages the NFTs that may be required by this contract.
     */
    ERC721 public NFTAddress;

    /**
     * @notice Address where remaining bullets are collected.
     * @dev Bullets are a secondary token used in the ecosystem.
     */
    address public remainingBulletCollector;

    /**
     * @notice Precision loss prevention multiplier constant.
     * @dev This value is used for precision management during calculations.
     */
    uint256 private constant ACCU_REWARD_MULTIPLIER = 10**20;

    /**
     * @notice Struct defining the data for each option.
     * @dev This includes the addresses of the option, bullet, sniper, and the bullet balance.
     */
    struct OptionData {
        address optionAddress;
        address bullet;
        address sniper;
        uint256 bulletBalance;
    }

    /**
     * @notice Struct defining the user's data.
     * @dev This includes total staking amount, last entry time, and accumulated rewards for both uHODL and bHODL.
     */
    struct UserData {
        uint256 totalStakingAmount;
        uint256 uHODLEntryAccuReward;
        uint256 bHODLEntryAccuReward;
        uint256 lastEntryTime;
    }

    /**
     * @notice Struct defining the pool's data.
     * @dev This includes the total staking amount and accumulated rewards for both uHODL and bHODL.
     */
    struct PoolData {
        uint256 stakingAmount;
        uint256 uHODLAccuReward;
        uint256 bHODLAccuReward;
    }

    /**
     * @notice Struct defining the staking data for each staker.
     * @dev This includes the current and claimed staking amount, and the block height when these amounts were updated.
     */
    struct StakingData {
        uint256 claimStakingAmount;
        uint256 claimAmountUpdateBlockHeight;
        uint256 currentStakingAmount;
        uint256 stakingAmountUpdateBlockHeight;
    }

    /**
     * @notice Mapping to store user data for each address.
     * @dev Keys are user addresses and values are UserData struct.
     */
    mapping(address => UserData) public userDatas;

    /**
     * @notice Mapping to store staking data for each staker.
     * @dev Keys are user addresses and values are StakingData struct.
     */
    mapping(address => StakingData) public stakingInfo;

    /**
     * @notice Mapping to store claim information for each NFT.
     * @dev Keys are NFT IDs and values are amounts.
     */
    mapping(uint256 => uint256) public nftClaimInfo;

    /**
     * @notice Mapping to store claim information for each user.
     * @dev Keys are user addresses and values are amounts.
     */
    mapping(address => uint256) public userClaimInfo;

    /**
     * @notice The start block of the last delivery.
     * @dev This is used for tracking purposes.
     */
    uint256 public lastDeliverStartBlock;

    /**
     * @notice The end block of the last delivery.
     * @dev This is used for tracking purposes.
     */
    uint256 public lastDeliverEndBlock;

    /**
     * @notice The total daily share for bullet reward.
     * @dev This is the total share of all users who staked more than the bulletRewardThreshold in a day.
     */
    uint256 public dailyTotalShareBullet;

    /**
     * @notice The total daily share for bullet reward in the last period.
     * @dev This is the total share of all users who staked more than the bulletRewardThreshold in the last period.
     */
    uint256 public lastPeriodDailyTotalShareBullet;

    /**
     * @notice The total claim amount in the last period.
     * @dev This is the total claim amount of all users in the last period.
     */
    uint256 public lastPeriodDailyClaimTotal;

    /**
     * @notice The data of the pool.
     * @dev This includes the total staking amount and accumulated rewards for both uHODL and bHODL.
     */
    PoolData public poolData;

    /**
     * @notice The address of the uHODL rewarder contract.
     * @dev This contract is responsible for distributing rewards to uHODL stakers.
     */
    IStakingPoolRewarder public uHODLRewarder;

    /**
     * @notice The address of the bHODL rewarder contract.
     * @dev This contract is responsible for distributing rewards to bHODL stakers.
     */
    IStakingPoolRewarder public bHODLRewarder;

    /**
     * @notice Emitted when a user stakes DOB tokens.
     * @dev Includes the staker's address and the amount staked.
     * @param staker The address of the user that staked the tokens.
     * @param amount The amount of tokens staked.
     */
    event Staked(address indexed staker, uint256 amount);

    /**
     * @notice Emitted when a user unstakes DOB tokens.
     * @dev Includes the staker's address and the amount unstaked.
     * @param staker The address of the user that unstaked the tokens.
     * @param amount The amount of tokens unstaked.
     */
    event Unstaked(address indexed staker, uint256 amount);

    /**
     * @notice Emitted when the worker is changed.
     * @dev Includes the old and new worker addresses.
     * @param oldWorker The address of the old worker.
     * @param newWorker The address of the new worker.
     */
    event WorkerChanged(address oldWorker, address newWorker);

    /**
     * @notice Emitted when the factory is changed.
     * @dev Includes the old and new factory addresses.
     * @param oldFactory The address of the old factory.
     * @param newFactory The address of the new factory.
     */
    event FactoryChanged(address oldFactory, address newFactory);

    /**
     * @notice Emitted when the rewarder is changed.
     * @dev Includes the old and new rewarder addresses.
     * @param oldRewarder The address of the old rewarder.
     * @param newRewarder The address of the new rewarder.
     */
    event RewarderChanged(address oldRewarder, address newRewarder);

    /**
     * @notice Emitted when a reward is redeemed.
     * @dev Includes the staker's address, the rewarder's address, the amount, and the reward type.
     * @param staker The address of the user that redeemed the reward.
     * @param rewarder The address of the rewarder contract.
     * @param amount The amount of reward redeemed.
     * @param rewardType The type of reward (0 for uHODL, 1 for bHODL).
     */
    event RewardRedeemed(address indexed staker, address rewarder, uint256 amount, uint8 rewardType);

    /**
     * @notice Emitted when the bullet reward threshold is changed.
     * @dev Includes the old and new threshold values.
     * @param oldThreshold The old bullet reward threshold.
     * @param newThreshold The new bullet reward threshold.
     */
    event BulletRewardThresholdChanged(uint256 oldThreshold, uint256 newThreshold);

    /**
     * @notice Emitted when the extend lock days is changed.
     * @dev Includes the old and new lock days values.
     * @param oldDays The old extend lock days.
     * @param newDays The new extend lock days.
     */
    event ExtendLockDaysChanged(uint256 oldDays, uint256 newDays);

    /**
     * @notice Emitted when a bullet reward is given.
     * @dev Includes the user's address, the bullet's address, and the amount.
     * @param user The address of the user that received the reward.
     * @param bullet The address of the bullet token contract.
     * @param amount The amount of bullet reward given.
     */
    event BulletReward(address user, address bullet, uint256 amount);

    /**
     * @notice This modifier ensures only the worker can call the function.
     * @dev Reverts if the caller is not the worker.
     */
    modifier onlyWorker() {
        require(msg.sender == worker, "DOBStaking: caller is not the worker");
        _;
    }

    /**
     * @notice This modifier ensures only the option factory can call the function.
     * @dev Reverts if the caller is not the option factory.
     */
    modifier onlyFactory() {
        require(msg.sender == optionFactory, "DOBStaking: caller is not the option factory");
        _;
    }

    /**
     * @notice Initializes the DOBStakingPool contract with essential parameters.
     * @dev The initializer function is used in upgradeable contracts instead of a constructor.
     *      It checks that input addresses are not zero and then sets up initial contract state.
     * @param _feeCollector The address of the fee collector.
     * @param _bulletCollector The address of the bullet collector.
     * @param _rewardDispatcher The address of the reward dispatcher.
     * @param _uHODL The address of the uHODL contract.
     * @param _bHODL The address of the bHODL contract.
     * @param _DOB The address of the DOB token.
     */
    function __DOBStakingPool_init(
        address _feeCollector,
        address _bulletCollector,
        address _rewardDispatcher,
        address _uHODL,
        address _bHODL,
        address _DOB
    ) public initializer {
        require(_feeCollector != address(0), "DOBStakingPool: zero address");
        require(_bulletCollector != address(0), "DOBStakingPool: zero address");
        require(_rewardDispatcher != address(0), "DOBStakingPool: zero address");
        require(_uHODL != address(0), "DOBStakingPool: zero address");
        require(_bHODL != address(0), "DOBStakingPool: zero address");
        require(_DOB != address(0), "DOBStakingPool: zero address");

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        feeCollector = _feeCollector;
        bulletCollector = _bulletCollector;
        rewardDispatcher = _rewardDispatcher;
        uHODL = _uHODL;
        bHODL = _bHODL;
        DOB = _DOB;

        // Setting initial parameters
        bulletRewardThreshold = 1000e18;
        extendLockDays = 30 days;
        lastWorkTimestamp = block.timestamp;
    }

    /**
     * @notice Changes the worker address to a new one.
     * @dev Emits a WorkerChanged event after successfully changing the worker.
     * @param _worker The new worker's address.
     */
    function setWorker(address _worker) external onlyOwner {
        require(_worker != address(0), "DOBStakingPool: zero address");

        address oldWorker = worker;
        worker = _worker;

        emit WorkerChanged(oldWorker, worker);
    }

    /**
     * @notice Changes the factory address to a new one.
     * @dev Emits a FactoryChanged event after successfully changing the factory.
     * @param newFactory The new factory's address.
     */
    function setFactory(address newFactory) external onlyOwner {
        require(newFactory != address(0), "DOBStakingPool: zero address");

        address oldFactory = optionFactory;
        optionFactory = newFactory;

        emit FactoryChanged(oldFactory, optionFactory);
    }

    /**
     * @notice Changes the uHODL rewarder address to a new one.
     * @dev Emits a RewarderChanged event after successfully changing the rewarder.
     * @param _uHODLRewarder The new uHODL rewarder's address.
     */
    function setuHODLRewarder(address _uHODLRewarder) external onlyOwner {
        require(_uHODLRewarder != address(0), "DOBStakingPool: zero address");

        address olduHODLRewarder = address(_uHODLRewarder);
        uHODLRewarder = IStakingPoolRewarder(_uHODLRewarder);

        emit RewarderChanged(olduHODLRewarder, _uHODLRewarder);
    }

    /**
     * @notice Changes the bHODL rewarder address to a new one.
     * @dev Emits a RewarderChanged event after successfully changing the rewarder.
     * @param _bHODLRewarder The new bHODL rewarder's address.
     */
    function setbHODLRewarder(address _bHODLRewarder) external onlyOwner {
        require(_bHODLRewarder != address(0), "DOBStakingPool: zero address");

        address oldbHODLRewarder = address(_bHODLRewarder);
        bHODLRewarder = IStakingPoolRewarder(_bHODLRewarder);

        emit RewarderChanged(oldbHODLRewarder, _bHODLRewarder);
    }

    /**
     * @notice Changes the bullet reward threshold to a new one.
     * @dev Emits a BulletRewardThresholdChanged event after successfully changing the threshold.
     * @param _threshold The new bullet reward threshold.
     */
    function setBulletRewardThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0, "DOBStakingPool: zero threshold");

        uint256 oldThreshold = bulletRewardThreshold;
        bulletRewardThreshold = _threshold;

        emit BulletRewardThresholdChanged(oldThreshold, _threshold);
    }

    /**
     * @notice Changes the extend lock days to a new value.
     * @dev Emits an ExtendLockDaysChanged event after successfully changing the days.
     * @param _days The new extend lock days.
     */
    function setExtendLockDays(uint256 _days) external onlyOwner {
        require(_days > 0, "DOBStakingPool: zero days");

        uint256 oldDays = extendLockDays;
        extendLockDays = _days;

        emit ExtendLockDaysChanged(oldDays, _days);
    }

    /**
     * @notice Changes the fee collector address to a new one.
     * @param _feeCollector The new fee collector's address.
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "DOBStakingPool: zero address");
        feeCollector = _feeCollector;
    }

    /**
     * @notice Changes the bullet collector address to a new one.
     * @param _bulletCollector The new bullet collector's address.
     */
    function setBulletCollector(address _bulletCollector) external onlyOwner {
        require(_bulletCollector != address(0), "DOBStakingPool: zero address");
        bulletCollector = _bulletCollector;
    }

    /**
     * @notice Changes the reward dispatcher address to a new one.
     * @param _rewardDispatcher The new reward dispatcher's address.
     */
    function setRewardDispatcher(address _rewardDispatcher) external onlyOwner {
        require(_rewardDispatcher != address(0), "DOBStakingPool: zero address");
        rewardDispatcher = _rewardDispatcher;
    }

    /**
     * @notice Changes the remaining bullet collector address to a new one.
     * @param _remainingBulletCollector The new remaining bullet collector's address.
     */
    function setRemainingBulletCollector(address _remainingBulletCollector) external onlyOwner {
        require(_remainingBulletCollector != address(0), "DOBStakingPool: zero address");
        remainingBulletCollector = _remainingBulletCollector;
    }

    /**
     * @notice Adds a new option to the activated options.
     * @dev Checks that none of the addresses are zero, and adds the option to the list of activated options.
     * @param _optionAddress The address of the new option.
     * @param _bulletAddress The address of the bullet for the new option.
     * @param _sniperAddress The address of the sniper for the new option.
     */
    function addOption(
        address _optionAddress,
        address _bulletAddress,
        address _sniperAddress
    ) external override onlyFactory {
        require(_optionAddress != address(0), "DOBStakingPool: zero address");
        require(_bulletAddress != address(0), "DOBStakingPool: zero address");
        require(_sniperAddress != address(0), "DOBStakingPool: zero address");

        uint256 bulletRewardAmount = IERC20Upgradeable(_bulletAddress).balanceOf(bulletCollector);
        activatedOptions.push(OptionData(_optionAddress, _bulletAddress, _sniperAddress, bulletRewardAmount));
    }

    /**
     * @notice Removes an option from the activated options.
     * @dev Iterates over the activated options, replaces the option to remove with the last element in the array, and removes the last element.
     * @param _optionAddress The address of the option to remove.
     */
    function removeOption(address _optionAddress) external override onlyFactory {
        require(_optionAddress != address(0), "DOBStakingPool: zero address");

        for (uint8 i = 0; i < activatedOptions.length; i++) {
            if (activatedOptions[i].optionAddress == _optionAddress) {
                activatedOptions[i] = activatedOptions[activatedOptions.length - 1];
                activatedOptions.pop();
                break;
            }
        }
    }

    /**
     * @notice Updates the list of activated options.
     * @dev Iterates over the activated options and removes those that have expired.
     */
    function updateActivatedOptions() internal {
        OptionData[] memory oldActivatedOptions = activatedOptions;
        delete activatedOptions;

        for (uint8 i = 0; i < oldActivatedOptions.length; i++) {
            uint256 expiryTime = IOption(oldActivatedOptions[i].optionAddress).getExpiryTime();
            if (block.timestamp <= expiryTime) {
                uint256 bulletRewardAmount = IERC20Upgradeable(oldActivatedOptions[i].bullet).balanceOf(bulletCollector);
                oldActivatedOptions[i].bulletBalance = bulletRewardAmount;
                activatedOptions.push(oldActivatedOptions[i]);
            }
        }
    }

    /**
     * @notice Returns the number of currently activated options.
     * @dev Checks the length property of the activatedOptions array.
     * @return A uint256 representing the number of activated options.
     */
    function activatedOptionLength() external view returns (uint256) {
        return activatedOptions.length;
    }

    /**
     * @notice This function allows a user to stake their DOB tokens.
     * @dev
     * - Ensures that the pool is not paused and that the function is not called within the same block the worker is updating.
     * - Calculates the pending uHODL and bHODL rewards for the user.
     * - Increases the user's total staking amount and the pool's staking amount by the amount staked.
     * - Updates the uHODL and bHODL entry rewards.
     * - Transfers the staked DOB tokens from the user to the contract.
     * - Settles any pending rewards with vesting.
     * - Updates the daily staking amount for bullet rewards.
     * @param amount The amount of DOB tokens to stake.
     */
    function stake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "DOBStaking: cannot stake zero amount");
        require(block.number != lastDeliverEndBlock, "DOBStaking: worker is updating in same block!");

        _accuHodlReward();
        uint256 uHODLRewardToVest = poolData
        .uHODLAccuReward
        .sub(userDatas[msg.sender].uHODLEntryAccuReward)
        .mul(userDatas[msg.sender].totalStakingAmount)
        .div(ACCU_REWARD_MULTIPLIER);
        uint256 bHODLRewardToVest = poolData
        .bHODLAccuReward
        .sub(userDatas[msg.sender].bHODLEntryAccuReward)
        .mul(userDatas[msg.sender].totalStakingAmount)
        .div(ACCU_REWARD_MULTIPLIER);

        userDatas[msg.sender].totalStakingAmount = userDatas[msg.sender].totalStakingAmount.add(amount);
        poolData.stakingAmount = poolData.stakingAmount.add(amount);

        userDatas[msg.sender].uHODLEntryAccuReward = poolData.uHODLAccuReward;
        userDatas[msg.sender].bHODLEntryAccuReward = poolData.bHODLAccuReward;

        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(DOB), msg.sender, address(this), amount);

        uHODLRewarder.onReward(1, msg.sender, uHODLRewardToVest, userDatas[msg.sender].lastEntryTime);
        bHODLRewarder.onReward(1, msg.sender, bHODLRewardToVest, userDatas[msg.sender].lastEntryTime);

        userDatas[msg.sender].lastEntryTime = block.timestamp;

        uint256 oldDailyStakingAmount = 0;
        if (
            stakingInfo[msg.sender].stakingAmountUpdateBlockHeight > lastDeliverEndBlock ||
            stakingInfo[msg.sender].currentStakingAmount < bulletRewardThreshold
        ) {
            oldDailyStakingAmount = stakingInfo[msg.sender].currentStakingAmount;
            stakingInfo[msg.sender].currentStakingAmount = stakingInfo[msg.sender].currentStakingAmount.add(amount);
        } else {
            stakingInfo[msg.sender].claimStakingAmount = stakingInfo[msg.sender].currentStakingAmount;
            stakingInfo[msg.sender].claimAmountUpdateBlockHeight = stakingInfo[msg.sender].stakingAmountUpdateBlockHeight;
            stakingInfo[msg.sender].currentStakingAmount = amount;
        }
        stakingInfo[msg.sender].stakingAmountUpdateBlockHeight = block.number;
        if (oldDailyStakingAmount >= bulletRewardThreshold) {
            dailyTotalShareBullet = dailyTotalShareBullet.add(amount);
        } else if (stakingInfo[msg.sender].currentStakingAmount >= bulletRewardThreshold) {
            dailyTotalShareBullet = dailyTotalShareBullet.add(stakingInfo[msg.sender].currentStakingAmount);
        }

        emit Staked(msg.sender, amount);
    }

    /**
     * @notice This function allows a user to unstake their DOB tokens.
     * @dev
     * - Checks that the pool is not paused, that the function is not called within the same block the worker is updating, and that the user's tokens have been staked for at least `extendLockDays`.
     * - Calculates the pending uHODL and bHODL rewards for the user.
     * - Decreases the user's total staking amount and the pool's staking amount by the amount unstaked.
     * - Updates the uHODL and bHODL entry rewards.
     * - Transfers the unstaked DOB tokens from the contract to the user.
     * - Settles any pending rewards with vesting.
     * - Updates the daily staking amount for bullet rewards.
     * @param amount The amount of DOB tokens to unstake.
     */
    function unstake(uint256 amount) external whenNotPaused nonReentrant {
        require(
            block.timestamp >= userDatas[msg.sender].lastEntryTime + extendLockDays,
            "DOBStaking: Less than unlock time"
        );
        require(block.number != lastDeliverEndBlock, "DOBStaking: worker is updating in same block!");

        _accuHodlReward();
        uint256 uHODLRewardToVest = poolData
        .uHODLAccuReward
        .sub(userDatas[msg.sender].uHODLEntryAccuReward)
        .mul(userDatas[msg.sender].totalStakingAmount)
        .div(ACCU_REWARD_MULTIPLIER);
        uint256 bHODLRewardToVest = poolData
        .bHODLAccuReward
        .sub(userDatas[msg.sender].bHODLEntryAccuReward)
        .mul(userDatas[msg.sender].totalStakingAmount)
        .div(ACCU_REWARD_MULTIPLIER);

        userDatas[msg.sender].totalStakingAmount = userDatas[msg.sender].totalStakingAmount.sub(amount);
        poolData.stakingAmount = poolData.stakingAmount.sub(amount);

        userDatas[msg.sender].uHODLEntryAccuReward = poolData.uHODLAccuReward;
        userDatas[msg.sender].bHODLEntryAccuReward = poolData.bHODLAccuReward;

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(DOB), msg.sender, amount);

        uHODLRewarder.onReward(1, msg.sender, uHODLRewardToVest, userDatas[msg.sender].lastEntryTime);
        bHODLRewarder.onReward(1, msg.sender, bHODLRewardToVest, userDatas[msg.sender].lastEntryTime);

        if (
            stakingInfo[msg.sender].stakingAmountUpdateBlockHeight > lastDeliverEndBlock ||
            stakingInfo[msg.sender].currentStakingAmount < bulletRewardThreshold
        ) {
            uint256 oldDailyStakingAmount = stakingInfo[msg.sender].currentStakingAmount;

            if (stakingInfo[msg.sender].currentStakingAmount < amount) {
                stakingInfo[msg.sender].currentStakingAmount = 0;
            } else {
                stakingInfo[msg.sender].currentStakingAmount = stakingInfo[msg.sender].currentStakingAmount.sub(amount);
            }
            if (oldDailyStakingAmount >= bulletRewardThreshold) {
                if (stakingInfo[msg.sender].currentStakingAmount < bulletRewardThreshold) {
                    dailyTotalShareBullet = dailyTotalShareBullet.sub(oldDailyStakingAmount);
                } else {
                    dailyTotalShareBullet = dailyTotalShareBullet.sub(amount);
                }
            }
        } else {
            stakingInfo[msg.sender].claimStakingAmount = stakingInfo[msg.sender].currentStakingAmount;
            stakingInfo[msg.sender].claimAmountUpdateBlockHeight = stakingInfo[msg.sender].stakingAmountUpdateBlockHeight;
            stakingInfo[msg.sender].currentStakingAmount = 0;
        }
        stakingInfo[msg.sender].stakingAmountUpdateBlockHeight = block.number;

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @notice This function allows the owner to enable or disable the NFT check, and to set the NFT contract address
     *          and the remaining bullet collector address.
     * @dev
     * - Checks that the provided NFT contract address and remaining bullet collector address are valid if `_isCheckNFT` is true.
     * - Sets `isCheckNFT`, `NFTAddress`, and `remainingBulletCollector` according to the provided arguments.
     * @param _isCheckNFT If true, the NFT check will be enabled.
     * @param _nftAddress The address of the NFT contract.
     * @param _remainingBulletCollector The address of the remaining bullet collector.
     */
    function setIsCheckNFT(
        bool _isCheckNFT,
        ERC721 _nftAddress,
        address _remainingBulletCollector
    ) public onlyOwner {
        if (_isCheckNFT) {
            require(address(_nftAddress) != address(0), "DOBStaking: NFT zero address");
            require(_remainingBulletCollector != address(0), "DOBStaking: surplus bullet collector zero address");
            uint256 size;
            assembly {
                size := extcodesize(_nftAddress)
            }
            require(size > 0, "Not a contract");
            NFTAddress = _nftAddress;
            remainingBulletCollector = _remainingBulletCollector;
        }
        isCheckNFT = _isCheckNFT;
    }

    /**
     * @notice This function checks if an NFT belonging to a user has already claimed rewards or not.
     * @dev
     * - Checks if `isCheckNFT` is true. If so, it requires that the provided NFT hasn't already claimed rewards.
     * - Checks if the owner of the NFT is the user. If these conditions are met, it returns true. Otherwise, it returns false.
     * @param _userAddress The address of the user to check.
     * @param _tokenId The ID of the NFT to check.
     * @return bool Returns true if the NFT check is successful, false otherwise.
     */

    function nftCheckSuccess(address _userAddress, uint256 _tokenId) private view returns (bool) {
        if (isCheckNFT) {
            require(nftClaimInfo[_tokenId] <= lastDeliverEndBlock, "DOBStaking:this nft has already claimed for rewards");
            if (NFTAddress.ownerOf(_tokenId) == _userAddress) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @notice Handles daily tasks for the smart contract.
     * @dev
     * - Can only be called by an account with the "Worker" role.
     * - Only executable when the contract is not paused.
     * - Ensures the last work has been done more than 18 hours ago.
     * - Loops over activated options, checks balance, makes transfers, and updates the contract's internal state.
     * @param _balanceCheck The boolean flag to check the balance.
     */
    function dailyWork(bool _balanceCheck) external onlyWorker whenNotPaused nonReentrant {
        require(block.timestamp > (lastWorkTimestamp + 18 hours), "DOBStaking: last work not over 18 hours");

        uint256 remainingAmount = lastPeriodDailyTotalShareBullet.sub(lastPeriodDailyClaimTotal);
        if (remainingAmount > 0 && lastPeriodDailyTotalShareBullet > 0) {
            for (uint8 j = 0; j < activatedOptions.length; j++) {
                if (activatedOptions[j].bulletBalance > 0) {
                    uint256 bulletAmount = activatedOptions[j].bulletBalance.mul(remainingAmount).div(
                        lastPeriodDailyTotalShareBullet
                    );

                    if (
                        _balanceCheck &&
                        IERC20Upgradeable(activatedOptions[j].bullet).balanceOf(bulletCollector) < bulletAmount
                    ) {
                        continue;
                    }

                    if (bulletAmount <= activatedOptions[j].bulletBalance) {
                        ITokenKeeper(bulletCollector).transferToken(
                            activatedOptions[j].bullet,
                            remainingBulletCollector,
                            bulletAmount
                        );
                        emit BulletReward(remainingBulletCollector, activatedOptions[j].bullet, bulletAmount);
                    }
                }
            }
        }

        updateActivatedOptions();
        lastPeriodDailyTotalShareBullet = dailyTotalShareBullet;
        lastPeriodDailyClaimTotal = 0;
        dailyTotalShareBullet = 0;
        lastDeliverStartBlock = lastDeliverEndBlock;
        lastDeliverEndBlock = block.number;
        lastWorkTimestamp = block.timestamp;
    }

    /**
     * @notice Draw BULLET rewards for a user.
     * @dev
     * - Requires the user hasn't claimed for rewards multiple times in one day.
     * - Checks that the user owns the NFT.
     * - Ensures there are some BULLET rewards left to claim.
     * - Checks the user's staking status and gives the BULLET rewards accordingly.
     * @param user The address of the user.
     * @param tokenID The id of the NFT.
     */
    function drawReward(address user, uint256 tokenID) external whenNotPaused nonReentrant {
        require(userClaimInfo[user] <= lastDeliverEndBlock, "DOBStaking: This user has already claimed for rewards");
        require(nftCheckSuccess(user, tokenID), "DOBStaking: You do not have the NFT");
        require(lastPeriodDailyTotalShareBullet > 0, "DOBStaking: lastPeriodDailyTotalShareBullet is zero");

        uint256 shareAmount = 0;
        if (
            stakingInfo[user].currentStakingAmount >= bulletRewardThreshold &&
            stakingInfo[user].stakingAmountUpdateBlockHeight > lastDeliverStartBlock &&
            stakingInfo[user].stakingAmountUpdateBlockHeight <= lastDeliverEndBlock
        ) {
            shareAmount = stakingInfo[user].currentStakingAmount;
        }
        if (
            stakingInfo[user].claimStakingAmount >= bulletRewardThreshold &&
            stakingInfo[user].claimAmountUpdateBlockHeight > lastDeliverStartBlock &&
            stakingInfo[user].claimAmountUpdateBlockHeight <= lastDeliverEndBlock
        ) {
            shareAmount = stakingInfo[user].claimStakingAmount;
        }

        require(shareAmount > 0, "DOBStaking: You do not have reward to claim");

        lastPeriodDailyClaimTotal += shareAmount;

        require(
            lastPeriodDailyClaimTotal <= lastPeriodDailyTotalShareBullet,
            "DOBStaking: claim total is large than share total"
        );

        for (uint8 j = 0; j < activatedOptions.length; j++) {
            uint256 bulletAmount = activatedOptions[j].bulletBalance.mul(shareAmount).div(lastPeriodDailyTotalShareBullet);
            if (bulletAmount > 0 && bulletAmount <= activatedOptions[j].bulletBalance) {
                ITokenKeeper(bulletCollector).transferToken(activatedOptions[j].bullet, user, bulletAmount);
                emit BulletReward(user, activatedOptions[j].bullet, bulletAmount);
            }
        }

        nftClaimInfo[tokenID] = block.number;
        userClaimInfo[user] = block.number;
    }

    /**
     * @notice Calculates and returns the total accumulated HODL rewards for a user.
     * @dev
     * - The total accumulated rewards for a user is the sum of pending rewards (rewards yet to be claimed) and rewards that are already vested and vesting.
     * - This function checks the pool's staking amount. If greater than zero, it calculates the amount of rewards for each staking token, and updates the real accumulated rewards.
     * - Then, it calculates the pending rewards, and sums them up with the rewards in the rewarder contract, which includes both vested and vesting rewards.
     * @param user The address of the user.
     * @return uHODLReward The total uHODL reward for the user.
     * @return bHODLReward The total bHODL reward for the user.
     */
    function getReward(address user) external view returns (uint256 uHODLReward, uint256 bHODLReward) {
        uint256 realuHODLAccuReward = poolData.uHODLAccuReward;
        uint256 realbHODLAccuReward = poolData.bHODLAccuReward;
        if (poolData.stakingAmount > 0) {
            uint256 uAmountForReward = IERC20Upgradeable(uHODL).balanceOf(feeCollector);
            uint256 bAmountForReward = IERC20Upgradeable(bHODL).balanceOf(feeCollector);

            realuHODLAccuReward = uAmountForReward.mul(ACCU_REWARD_MULTIPLIER).div(poolData.stakingAmount).add(
                realuHODLAccuReward
            );
            realbHODLAccuReward = bAmountForReward.mul(ACCU_REWARD_MULTIPLIER).div(poolData.stakingAmount).add(
                realbHODLAccuReward
            );
        }

        uint256 uHODLpendingReward = realuHODLAccuReward
        .sub(userDatas[user].uHODLEntryAccuReward)
        .mul(userDatas[user].totalStakingAmount)
        .div(ACCU_REWARD_MULTIPLIER);
        uint256 bHODlpendingReward = realbHODLAccuReward
        .sub(userDatas[user].bHODLEntryAccuReward)
        .mul(userDatas[user].totalStakingAmount)
        .div(ACCU_REWARD_MULTIPLIER);

        uint256 uHODLRewardInRewarder = uHODLRewarder.calculateTotalReward(user, 1);
        uint256 bHODLRewardInRewarder = bHODLRewarder.calculateTotalReward(user, 1);

        uHODLReward = uHODLpendingReward.add(uHODLRewardInRewarder);
        bHODLReward = bHODlpendingReward.add(bHODLRewardInRewarder);
    }

    /**
     * @notice Allows the user to claim their HODL rewards.
     * @dev This function calculates the pending reward for a user, settles these rewards to the rewarder contract with vesting, and then attempts to claim withdrawable rewards from the rewarder.
     * - It requires that the claimable rewards are more than zero and emits a RewardRedeemed event for each token reward that is claimed.
     */
    function redeemReward() external nonReentrant whenNotPaused {
        _accuHodlReward();
        uint256 uHODLRewardToVest = poolData
        .uHODLAccuReward
        .sub(userDatas[msg.sender].uHODLEntryAccuReward)
        .mul(userDatas[msg.sender].totalStakingAmount)
        .div(ACCU_REWARD_MULTIPLIER);
        uint256 bHODLRewardToVest = poolData
        .bHODLAccuReward
        .sub(userDatas[msg.sender].bHODLEntryAccuReward)
        .mul(userDatas[msg.sender].totalStakingAmount)
        .div(ACCU_REWARD_MULTIPLIER);

        uHODLRewarder.onReward(1, msg.sender, uHODLRewardToVest, userDatas[msg.sender].lastEntryTime);
        userDatas[msg.sender].uHODLEntryAccuReward = poolData.uHODLAccuReward;
        bHODLRewarder.onReward(1, msg.sender, bHODLRewardToVest, userDatas[msg.sender].lastEntryTime);
        userDatas[msg.sender].bHODLEntryAccuReward = poolData.bHODLAccuReward;

        uint256 uHODLClaimable = uHODLRewarder.calculateWithdrawableReward(msg.sender, 1);
        uint256 bHODLClaimable = bHODLRewarder.calculateWithdrawableReward(msg.sender, 1);
        require(uHODLClaimable > 0 || bHODLClaimable > 0, "DOBStaking: haven't withdrawable reward");
        if (uHODLClaimable > 0) {
            uint256 claimed = uHODLRewarder.claimVestedReward(1, msg.sender);
            emit RewardRedeemed(msg.sender, address(uHODLRewarder), claimed, 0);
        }

        if (bHODLClaimable > 0) {
            uint256 claimed = bHODLRewarder.claimVestedReward(1, msg.sender);
            emit RewardRedeemed(msg.sender, address(bHODLRewarder), claimed, 1);
        }
    }

    /**
     * @notice Internal function that accumulates the HODL reward.
     * @dev This function checks the pool's staking amount, if it is greater than zero, it transfers the reward amount from the fee collector to the reward dispatcher and updates the accumulated rewards.
     */
    function _accuHodlReward() internal {
        if (poolData.stakingAmount > 0) {
            uint256 uAmountForReward = IERC20Upgradeable(uHODL).balanceOf(feeCollector);
            uint256 bAmountForReward = IERC20Upgradeable(bHODL).balanceOf(feeCollector);
            if (uAmountForReward > 0) {
                SafeERC20Upgradeable.safeTransferFrom(
                    IERC20Upgradeable(uHODL),
                    feeCollector,
                    rewardDispatcher,
                    uAmountForReward
                );
            }
            if (bAmountForReward > 0) {
                SafeERC20Upgradeable.safeTransferFrom(
                    IERC20Upgradeable(bHODL),
                    feeCollector,
                    rewardDispatcher,
                    bAmountForReward
                );
            }
            poolData.uHODLAccuReward = uAmountForReward.mul(ACCU_REWARD_MULTIPLIER).div(poolData.stakingAmount).add(
                poolData.uHODLAccuReward
            );
            poolData.bHODLAccuReward = bAmountForReward.mul(ACCU_REWARD_MULTIPLIER).div(poolData.stakingAmount).add(
                poolData.bHODLAccuReward
            );
        }
    }

    /**
     * @notice Allows a user to unstake their tokens in case of an emergency.
     * @dev This function can only be called when the contract is paused. It updates the pool's total staking amount and transfers the user's staking amount back to the user.
     */
    function emergencyUnstake() external whenPaused {
        require(userDatas[msg.sender].totalStakingAmount > 0, "DOBStaking: total staking amount is zero");
        uint256 amount = userDatas[msg.sender].totalStakingAmount;
        userDatas[msg.sender].totalStakingAmount = 0;
        poolData.stakingAmount = poolData.stakingAmount.sub(amount);

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(DOB), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @notice Pauses the contract, preventing certain actions until unpaused.
     * @dev Only callable by the owner of the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }
}