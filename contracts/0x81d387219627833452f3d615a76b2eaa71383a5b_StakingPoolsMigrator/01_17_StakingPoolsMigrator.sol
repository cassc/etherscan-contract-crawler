// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

import "./AttoDecimal.sol";
import "./IOMV1ToV2Migrator.sol";
import "./StakingPool.sol";
import "./IStakingPoolMigrator.sol";
import "./stakingPoolV1/StakingPoolV1.sol";

contract StakingPoolsMigrator is IStakingPoolMigrator, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AttoDecimalLib for AttoDecimal;

    enum StakingPoolRewardAction {NONE, STAKE, WITHDRAW}

    struct StakingPoolReward {
        uint256 amount;
        bool paid;
    }

    struct Account {
        bool lockedAmountPaid;
        uint256 lockedAmount;
        uint256 requiredAmount;
        AttoDecimal lockedPrice;
    }

    /// @notice True when contract has been initialized
    bool public initialized;

    /// @notice Timestamp when contract was initialized
    uint256 public initializingTimestamp;
    /// @notice Sum locked in contract synthetic tokens amount
    uint256 public lockedSyntheticAmount;
    /// @notice Staked in pool v1 balance (excluding compensated ones)
    uint256 public override(IStakingPoolMigrator) stakingPoolV1Balance;
    /// @notice Compensated staked amount for pool v1
    uint256 public stakingPoolV1IssueCompensationAmount;
    /// @notice Rewarding interval in seconds in pool v1
    uint256 public stakingPoolV1RewardInterval;

    /// @notice Address of deployer. Needs for validation account, that calls contract initializing
    address public deployer;

    /// @notice Address of tokens migration contract
    IOMV1ToV2Migrator public tokenMigrator;
    /// @notice Address of staking pool v1
    StakingPoolV1 public stakingPoolV1;
    /// @notice Address of staking pool v2
    StakingPool public stakingPoolV2;

    AttoDecimal private _startPrice;
    mapping(address => Account) public accounts;

    /// @dev To write blocks-dependent tests all block.number receiving was moved into this virtual method that has been overridden in mocked contract
    function getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /// @dev To write time-dependent tests all block.timestamps receiving was moved into this virtual method that has been overridden in mocked contract
    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice Price of synthetic token that was when migrator was initialized
    function startPrice()
        public
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return _startPrice.toTuple();
    }

    /// @notice Staked in pool v1 amount
    /// @dev Since the issue in staking pool v1
    ///     compensated amount should not been taken into accounts in price calculations
    function stakingPoolV1SignificantBalance() public view onlyInitialized returns (uint256 stakingPoolV1Balance_) {
        IERC20 omV1 = stakingPoolV1.stakingToken();
        return omV1.balanceOf(address(stakingPoolV1)).sub(stakingPoolV1IssueCompensationAmount);
    }

    /// @notice Calculate all data, that should be used for synthetic token price calculations
    /// @return stakingPoolV1Balance_ Staked balance in pool v1
    /// @return burnedSyntheticAmount Synthetic tokens amount, that should be burned before next price calculations
    function calculatePriceParams()
        public
        view
        override(IStakingPoolMigrator)
        onlyInitialized
        returns (uint256 stakingPoolV1Balance_, uint256 burnedSyntheticAmount)
    {
        uint256 prevStakingPoolV1Balance = stakingPoolV1Balance;
        stakingPoolV1Balance_ = stakingPoolV1SignificantBalance();
        uint256 omDiff = prevStakingPoolV1Balance.sub(stakingPoolV1Balance_);
        (uint256 storedPriceMantissa, , ) = stakingPoolV2.priceStored();
        AttoDecimal memory price = AttoDecimal(storedPriceMantissa);
        burnedSyntheticAmount = AttoDecimalLib.div(omDiff, price).floor();
    }

    event Initialized();

    event StakingPoolV1RewardLocked(
        address indexed account,
        uint256 stakingPoolV1Reward,
        uint256 transferedSyntheticAmount
    );

    event StakingPoolV2RewardLocked(address indexed account, uint256 amount);
    event Updated(uint256 stakingPoolV1Balance, uint256 lockedSyntheticAmount);

    /// @param tokenMigrator_ Address of tokens migration contract
    /// @param stakingPoolV1_ Address of staking pool v1 contract
    /// @param stakingPoolV2_ Address of staking pool v2 contract
    /// @param stakingPoolV1RewardInterval_ Rewarding interval in staking pool v1 contract
    /// @dev `stakingPoolV1RewardInterval_` argument needed cause in staking pool v1 this variable is private
    ///     and contract has no view method for it
    constructor(
        IOMV1ToV2Migrator tokenMigrator_,
        StakingPoolV1 stakingPoolV1_,
        StakingPool stakingPoolV2_,
        uint256 stakingPoolV1RewardInterval_
    ) public {
        tokenMigrator = tokenMigrator_;
        stakingPoolV1 = stakingPoolV1_;
        stakingPoolV2 = stakingPoolV2_;
        require(stakingPoolV1RewardInterval_ > 0, "Reward interval not positive");
        stakingPoolV1RewardInterval = stakingPoolV1RewardInterval_;
        deployer = msg.sender;
        (uint256 defaultPriceMantissa, , ) = stakingPoolV2.DEFAULT_PRICE();
        _startPrice = AttoDecimal(defaultPriceMantissa);
    }

    /// @notice Initialize contract
    /// @param stakingPoolV1IssueCompensationAmount_ Amount of OM v1 tokens that this contract should stake in pool v1
    ///     to prevent locking of users' tokens in pool v1.
    function initialize(address stakingPoolV1IssueCompensator, uint256 stakingPoolV1IssueCompensationAmount_)
        external
        nonReentrant
        returns (bool success)
    {
        require(msg.sender == deployer, "Only deployer allowed to initialize contract");
        require(!initialized, "Already initialized");
        address stakingPoolV1Owner = stakingPoolV1.owner();
        IERC20 omTokenV1 = stakingPoolV1.stakingToken();
        stakingPoolV1IssueCompensationAmount = stakingPoolV1IssueCompensationAmount_;
        if (stakingPoolV1IssueCompensationAmount_ > 0) {
            omTokenV1.safeTransferFrom(
                stakingPoolV1IssueCompensator,
                address(this),
                stakingPoolV1IssueCompensationAmount_
            );
            omTokenV1.approve(address(stakingPoolV1), stakingPoolV1IssueCompensationAmount_);
            stakingPoolV1.stake(stakingPoolV1IssueCompensationAmount_);
        }
        stakingPoolV1.acceptOwnership();
        stakingPoolV1.setMinStakeBalance(uint256(-1));
        uint256 lockedStakingPoolV1Reward = stakingPoolV1.rewardDistributorBalanceOf();
        if (lockedStakingPoolV1Reward > 0) {
            stakingPoolV1.removeRewardSupply(lockedStakingPoolV1Reward);
            omTokenV1.safeTransfer(stakingPoolV1Owner, lockedStakingPoolV1Reward);
        }
        stakingPoolV1.nominateNewOwner(stakingPoolV1Owner);
        stakingPoolV2.initializeMigrator();
        stakingPoolV2.update();
        (uint256 startPriceMantissa, , ) = stakingPoolV2.priceStored();
        _startPrice = AttoDecimal(startPriceMantissa);
        initializingTimestamp = getTimestamp();
        (stakingPoolV1Balance, lockedSyntheticAmount) = calculateStakingPoolV1BalanceAndExpectedLockedSyntheticAmount();
        initialized = true;
        emit Initialized();
        stakingPoolV2.mint(address(this), lockedSyntheticAmount);
        return true;
    }

    /// @notice Locks all not received rewards from both staking pools and immediately stakes them
    function lockStakingPoolV1Rewards() external nonReentrant onlyInitialized returns (bool success) {
        address caller = msg.sender;
        Account storage account = accounts[caller];
        require(account.lockedPrice.mantissa == 0, "Staking pool V1 rewards already locked");
        uint256 stakingPoolV1StakedBalance = stakingPoolV1.balanceOf(caller);
        require(stakingPoolV1StakedBalance > 0, "No staked balance in staking pool v1");
        uint256 stakingPoolV1Reward;
        {
            uint256 rewardsLastLockingTime = stakingPoolV1.stakeTime(caller);
            uint256 stakingTime = initializingTimestamp.sub(rewardsLastLockingTime);
            uint256 passedIntervalsCount = stakingTime.div(stakingPoolV1RewardInterval);
            uint256 rewardPerIntervalDivider = stakingPoolV1.rewardPerIntervalDivider();
            uint256 perIntervalReward = stakingPoolV1StakedBalance.div(rewardPerIntervalDivider);
            stakingPoolV1Reward = passedIntervalsCount.mul(perIntervalReward);
        }

        stakingPoolV2.update();
        (uint256 currentPriceMantissa, , ) = stakingPoolV2.priceStored();
        AttoDecimal memory currentPrice = AttoDecimal(currentPriceMantissa);
        account.lockedPrice = currentPrice;

        uint256 stakingPoolV1UnstakedBalance = stakingPoolV1.unstakingBalanceOf(caller);
        uint256 totalUserBalanceInStakingPoolV1 = stakingPoolV1StakedBalance.add(stakingPoolV1UnstakedBalance);
        AttoDecimal memory multiplier = AttoDecimalLib.div(1, _startPrice).sub(AttoDecimalLib.div(1, currentPrice));
        uint256 syntheticAmount = multiplier.mul(totalUserBalanceInStakingPoolV1).floor();
        lockedSyntheticAmount = lockedSyntheticAmount.sub(syntheticAmount);
        stakingPoolV2.transfer(caller, syntheticAmount);

        uint256 amountToMint = AttoDecimalLib.div(stakingPoolV1Reward, currentPrice).floor();
        stakingPoolV2.mint(caller, amountToMint);
        stakingPoolV2.unlockRewards(stakingPoolV1Reward);
        emit StakingPoolV1RewardLocked(caller, stakingPoolV1Reward, syntheticAmount);
        return true;
    }

    /// @notice Locks all not received rewards from pool v2 for period from calling `lockStakingPoolV1Rewards`
    function lockStakingPoolV2Rewards() external nonReentrant onlyInitialized returns (bool success) {
        stakingPoolV2.update();
        address caller = msg.sender;
        Account storage account = accounts[caller];
        require(account.lockedAmount == 0 && account.requiredAmount == 0, "Already locked");
        require(account.lockedPrice.mantissa > 0, "Staking pool v1 rewards not locked");
        uint256 stakingPoolV1StakedBalance = stakingPoolV1.balanceOf(caller);
        require(stakingPoolV1StakedBalance == 0, "Not exited from staking pool v1");
        uint256 stakingPoolV1UnstakedBalance = stakingPoolV1.unstakingBalanceOf(caller);
        require(stakingPoolV1UnstakedBalance > 0, "Nothing to lock");
        (uint256 currentPriceMantissa, , ) = stakingPoolV2.priceStored();
        AttoDecimal memory currentPrice = AttoDecimal(currentPriceMantissa);
        uint256 sumStakedAmount = stakingPoolV1StakedBalance.add(stakingPoolV1UnstakedBalance);
        uint256 lockedAmount_ = currentPrice.div(account.lockedPrice).sub(1).mul(sumStakedAmount).floor();
        uint256 synthBurned = stakingPoolV2.unstakeLocked(lockedAmount_);
        lockedSyntheticAmount = lockedSyntheticAmount.sub(synthBurned);
        account.lockedAmount = lockedAmount_;
        account.requiredAmount = sumStakedAmount;
        emit StakingPoolV2RewardLocked(caller, lockedAmount_);
        return true;
    }

    /// @notice Stakes all locked rewards from `lockStakingPoolV2Rewards` method
    ///     and approved OM v1 tokens from staking pool v1
    function migrate() external nonReentrant onlyInitialized returns (bool success) {
        address caller = msg.sender;
        Account storage account = accounts[caller];
        require(!account.lockedAmountPaid, "Staking pool v2 locked rewards already paid");
        IERC20 omTokenV1 = stakingPoolV1.stakingToken();
        uint256 lockedAmount = account.lockedAmount;
        uint256 requiredAmount = account.requiredAmount;
        require(lockedAmount > 0 || requiredAmount > 0, "Staking pool v2 rewards not locked");
        omTokenV1.safeTransferFrom(caller, address(this), requiredAmount);
        omTokenV1.approve(address(tokenMigrator), requiredAmount);
        tokenMigrator.migrate(requiredAmount);
        IERC20 omTokenV2 = stakingPoolV2.stakingToken();
        uint256 stakingAmount = lockedAmount.add(requiredAmount);
        omTokenV2.approve(address(stakingPoolV2), stakingAmount);
        stakingPoolV2.stakeForUser(caller, stakingAmount);
        account.lockedAmountPaid = true;
        return true;
    }

    /// @notice Updates staked in pool v1 balance
    ///     and burns the amount of synthetic tokens corresponding to the missing amount
    function update() external override(IStakingPoolMigrator) onlyInitialized returns (bool success) {
        uint256 burnedSyntheticAmount;
        (stakingPoolV1Balance, burnedSyntheticAmount) = calculatePriceParams();
        lockedSyntheticAmount = lockedSyntheticAmount.sub(burnedSyntheticAmount);
        emit Updated(stakingPoolV1Balance, lockedSyntheticAmount);
        stakingPoolV2.burn(burnedSyntheticAmount);
        return true;
    }

    /// @notice Calculates pool v1 staked balance
    ///     and expected synthetic tokens amount, that should be locked in this contract
    /// @return stakingPoolV1Balance_ Staked in pool v1 balance
    /// @return expectedLockedSyntheticAmount Expected sythetic tokens amount, that should be locked in this contract
    function calculateStakingPoolV1BalanceAndExpectedLockedSyntheticAmount()
        public
        view
        returns (uint256 stakingPoolV1Balance_, uint256 expectedLockedSyntheticAmount)
    {
        IERC20 omV1 = stakingPoolV1.stakingToken();
        stakingPoolV1Balance_ = omV1.balanceOf(address(stakingPoolV1)).sub(stakingPoolV1IssueCompensationAmount);
        expectedLockedSyntheticAmount = AttoDecimalLib.div(stakingPoolV1Balance_, _startPrice).floor();
    }

    /// @notice Allows to call methods only when contract has been initialized
    modifier onlyInitialized() {
        require(initialized, "Not initialized");
        _;
    }
}