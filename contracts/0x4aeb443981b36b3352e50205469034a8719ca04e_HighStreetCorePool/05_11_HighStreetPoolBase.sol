// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ICorePool.sol";
import "./HighStreetPoolFactory.sol";

/**
 * @title HighStreet Pool Base
 *
 * @notice An abstract contract containing common logic for a core pool (permanent pool like HIGH/ETH or HIGH pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (HighStreetPoolFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - HIGH token address
 *          - pool token address, it can be HIGH token address, HIGH/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 20% for HIGH pool and 80% for HIGH/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 * @dev For HIGH Pool we use 200 as weight and for HIGH/ETH pool - 800.
 *
 */
abstract contract HighStreetPoolBase is IPool, ReentrancyGuard {
    /// @dev Data structure representing token holder using a pool
    struct User {
        // @dev Total staked amount
        uint256 tokenAmount;
        // @dev Total reward amount
        uint256 rewardAmount;
        // @dev Total weight
        uint256 totalWeight;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev Auxiliary variable for vault rewards calculation
        uint256 subVaultRewards;
        // @dev An array of holder's deposits
        Deposit[] deposits;
    }

    /// @dev Link to HIGH STREET ERC20 Token instance
    address public immutable override HIGH;

    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => User) public users;

    /// @dev Link to the pool factory HighStreetPoolFactory instance
    HighStreetPoolFactory public immutable factory;

    /// @dev Link to the pool token instance, for example HIGH or HIGH/ETH pair
    address public immutable override poolToken;

    /// @dev Pool weight, 200 for HIGH pool or 800 for HIGH/ETH
    uint256 public override weight;

    /// @dev Block number of the last yield distribution event
    uint256 public override lastYieldDistribution;

    /// @dev Used to calculate yield rewards
    /// @dev This value is different from "reward per token" used in locked pool
    /// @dev Note: stakes are different in duration and "weight" reflects that
    uint256 public override yieldRewardsPerWeight;

    /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
    uint256 public override usersLockingWeight;

    /**
     * @dev Stake weight is proportional to deposit amount and time locked, precisely
     *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e24 constant, as an integer
     * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e24
     * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
     *      weight is a deposit amount multiplied by 2 * 1e24
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e24;

    /**
     * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
     *      we use simplified calculation and use the following constant instead previos one
     */
    uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

    /**
     * @dev Rewards per weight are stored multiplied by 1e48, as integers.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e48;

    /**
     * @dev We want to get deposits batched but not one by one, thus here is define the size of each batch.
     */
    uint256 internal constant DEPOSIT_BATCH_SIZE  = 20;

    /**
     * @dev Fired in _stake() and stake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     */
    event Staked(address indexed _by, address indexed _from, uint256 amount);

    /**
     * @dev Fired in _updateStakeLock() and updateStakeLock()
     *
     * @param _by an address which performed an operation
     * @param depositId updated deposit ID
     * @param lockedFrom deposit locked from value
     * @param lockedUntil updated deposit locked until value
     */
    event StakeLockUpdated(address indexed _by, uint256 depositId, uint64 lockedFrom, uint64 lockedUntil);

    /**
     * @dev Fired in _unstake() and unstake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     */
    event Unstaked(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current block number
     */
    event Synchronized(address indexed _by, uint256 yieldRewardsPerWeight, uint256 lastYieldDistribution);

    /**
     * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param _to an address which claimed the yield reward
     * @param amount amount of yield paid
     */
    event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in setWeight()
     *
     * @param _fromVal old pool weight value
     * @param _toVal new pool weight value
     */
    event PoolWeightUpdated(uint256 _fromVal, uint256 _toVal);

    /**
     * @dev Fired in _emergencyWithdraw()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param amount amount of tokens withdraw
     */
    event EmergencyWithdraw(address indexed _by, uint256 amount);

    /**
     * @dev Overridden in sub-contracts to construct the pool
     *
     * @param _high HIGH ERC20 Token IlluviumERC20 address
     * @param _factory Pool factory HighStreetPoolFactory instance/address
     * @param _poolToken token the pool operates on, for example HIGH or HIGH/ETH pair
     * @param _initBlock initial block used to calculate the rewards
     *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    constructor(
        address _high,
        HighStreetPoolFactory _factory,
        address _poolToken,
        uint256 _initBlock,
        uint256 _weight
    ) {
        // verify the inputs are set
        require(_high != address(0), "high token address not set");
        require(address(_factory) != address(0), "HIGH Pool fct address not set");
        require(_poolToken != address(0), "pool token address not set");
        require(_initBlock >= blockNumber(), "Invalid init block");
        require(_weight > 0, "pool weight not set");

        // verify HighStreetPoolFactory instance supplied
        require(
            _factory.FACTORY_UID() == 0x484a992416a6637667452c709058dccce100b22b278536f5a6d25a14b6a1acdb,
            "unexpected FACTORY_UID"
        );

        // save the inputs into internal state variables
        HIGH = _high;
        factory = _factory;
        poolToken = _poolToken;
        weight = _weight;

        // init the dependent internal state variables
        lastYieldDistribution = _initBlock;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified
     *
     * @param _staker an address to calculate yield rewards value for
     * @return calculated yield reward value for the given address
     */
    function pendingYieldRewards(address _staker) external view override returns (uint256) {
        // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;

        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (blockNumber() > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 endBlock = factory.endBlock();
            uint256 multiplier =
                blockNumber() > endBlock ? endBlock - lastYieldDistribution : blockNumber() - lastYieldDistribution;
            uint256 highRewards = (multiplier * weight * factory.highPerBlock()) / factory.totalWeight();

            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight = rewardToWeight(highRewards, usersLockingWeight) + yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        // based on the rewards per weight value, calculate pending rewards;
        User memory user = users[_staker];
        uint256 pending = weightToReward(user.totalWeight, newYieldRewardsPerWeight) - user.subYieldRewards;

        return pending;
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user) external view override returns (uint256) {
        // read specified user token amount and return
        return users[_user].tokenAmount;
    }

    /**
     * @notice Returns information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address _user, uint256 _depositId) external view override returns (Deposit memory) {
        // read deposit at specified index and return
        return users[_user].deposits[_depositId];
    }

    /**
     * @notice Returns a batch of deposits on the given pageId for the given address
     *
     * @dev we separate deposits into serveral of pages, and each page have DEPOSIT_BATCH_SIZE of item.
     *
     * @param _user an address to query deposit for
     * @param _pageId zero-indexed page ID for the address specified
     * @return deposits info as Deposit structure
     */
    function getDepositsBatch(address _user, uint256 _pageId) external view returns (Deposit[] memory) {
        uint256 pageStart = _pageId * DEPOSIT_BATCH_SIZE;
        uint256 pageEnd = (_pageId + 1) * DEPOSIT_BATCH_SIZE;
        uint256 pageLength = DEPOSIT_BATCH_SIZE;

        if(pageEnd > (users[_user].deposits.length - pageStart)) {
            pageEnd = users[_user].deposits.length;
            pageLength = pageEnd - pageStart;
        }

        Deposit[] memory deposits = new Deposit[](pageLength);
        for(uint256 i = pageStart; i < pageEnd; i++) {
            deposits[i-pageStart] = users[_user].deposits[i];
        }
        return deposits;
    }

    /**
     * @notice Returns number of pages for the given address. Allows iteration over deposits.
     *
     * @dev See getDepositsBatch
     *
     * @param _user an address to query deposit length for
     * @return number of pages for the given address
     */
    function getDepositsBatchLength(address _user) external view returns (uint256) {
        if(users[_user].deposits.length == 0) {
            return 0;
        }
        return 1 + (users[_user].deposits.length - 1) / DEPOSIT_BATCH_SIZE;
    }

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user) external view override returns (uint256) {
        // read deposits array length and return
        return users[_user].deposits.length;
    }

    /**
     * @notice Stakes specified amount of tokens for the specified amount of time,
     *      and pays pending yield rewards if any
     *
     * @dev Requires amount to stake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _amount amount of tokens to stake
     * @param _lockUntil stake period as unix timestamp; zero means no locking
     */
    function stake (
        uint256 _amount,
        uint64 _lockUntil
    ) external override nonReentrant {
        // delegate call to an internal function
        _stake(msg.sender, _amount, _lockUntil);
    }

    /**
     * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function unstake(
        uint256 _depositId,
        uint256 _amount
    ) external override nonReentrant {
        // delegate call to an internal function
        _unstake(msg.sender, _depositId, _amount);
    }

    /**
     * @notice Extends locking period for a given deposit
     *
     * @dev Requires new lockedUntil value to be:
     *      higher than the current one, and
     *      in the future, but
     *      no more than 1 year in the future
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param depositId updated deposit ID
     * @param lockedUntil updated deposit locked until value
     */
    function updateStakeLock(
        uint256 depositId,
        uint64 lockedUntil
    ) external nonReentrant {
        require(users[msg.sender].deposits[depositId].tokenAmount > 0, "Invalid amount");

        // sync and call processRewards
        _sync();
        _processRewards(msg.sender, false);
        // delegate call to an internal function
        _updateStakeLock(msg.sender, depositId, lockedUntil);
    }

    /**
     * @notice Service function to synchronize pool state with current time
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one block passes between synchronizations
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function sync() external override {
        // delegate call to an internal function
        _sync();
    }

    /**
     * @notice Service function to calculate and pay pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function processRewards() external virtual override nonReentrant {
        // delegate call to an internal function
        _processRewards(msg.sender, true);
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating
     *
     * @dev Set weight to zero to disable the pool
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint256 _weight) external override {
        // verify function is executed by the factory
        require(msg.sender == address(factory), "access denied");

        // emit an event logging old and new weight values
        emit PoolWeightUpdated(weight, _weight);

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time/blocks which might have passed
     *
     * @param _staker an address to calculate yield rewards value for
     * @return pending calculated yield reward value for the given address
     */
    function _pendingYieldRewards(address _staker) internal view returns (uint256 pending) {
        // read user data structure into memory
        User memory user = users[_staker];

        // and perform the calculation using the values read
        return weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     * @param _lockUntil stake period as unix timestamp; zero means no locking
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockUntil
    ) internal virtual {
        // validate the inputs
        require(_amount > 0, "zero amount");
        require(
            _lockUntil == 0 || (_lockUntil > now256() && _lockUntil - now256() <= 365 days),
            "invalid lock interval"
        );

        // update smart contract state
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }

        // in most of the cases added amount `addedAmount` is simply `_amount`
        // however for deflationary tokens this can be different

        // read the current balance
        uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
        // transfer `_amount`; note: some tokens may get burnt here
        transferPoolTokenFrom(msg.sender, address(this), _amount);
        // read new balance, usually this is just the difference `previousBalance - _amount`
        uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
        // calculate real amount taking into account deflation
        uint256 addedAmount = newBalance - previousBalance;

        // set the `lockFrom` and `lockUntil` taking into account that
        // zero value for `_lockUntil` means "no locking" and leads to zero values
        // for both `lockFrom` and `lockUntil`
        uint64 lockFrom = _lockUntil > 0 ? uint64(now256()) : 0;
        uint64 lockUntil = _lockUntil;

        // stake weight formula rewards for locking
        uint256 stakeWeight =
            (((lockUntil - lockFrom) * WEIGHT_MULTIPLIER) / 365 days + WEIGHT_MULTIPLIER) * addedAmount;

        // makes sure stakeWeight is valid
        require(stakeWeight > 0, "invalid stakeWeight");

        // create and save the deposit (append it to deposits array)
        Deposit memory deposit =
            Deposit({
                tokenAmount: addedAmount,
                weight: stakeWeight,
                lockedFrom: lockFrom,
                lockedUntil: lockUntil,
                isYield: false
            });
        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);

        // update user record
        user.tokenAmount += addedAmount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update global variable
        usersLockingWeight += stakeWeight;

        // emit an event
        emit Staked(msg.sender, _staker, addedAmount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual {
        // verify an amount is set
        require(_amount > 0, "zero amount");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];
        // deposit structure may get deleted, so we save isYield flag to be able to use it
        bool isYield = stakeDeposit.isYield;

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards(_staker, false);

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;
        uint256 newWeight =
            (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
                365 days +
                WEIGHT_MULTIPLIER) * (stakeDeposit.tokenAmount - _amount);

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount - _amount == 0) {
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update global variable
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        // if the deposit was created by the pool itself as a yield reward
        if (isYield) {
            user.rewardAmount -= _amount;
            // mint the yield via the factory
            factory.mintYieldTo(msg.sender, _amount);
        } else {
            // otherwise just return tokens back to holder
            transferPoolToken(msg.sender, _amount);
        }

        // emit an event
        emit Unstaked(msg.sender, _staker, _amount);
    }

    /**
     * @notice Emergency withdraw specified amount of tokens
     *
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function emergencyWithdraw() external nonReentrant {
        require(factory.totalWeight() == 0, "totalWeight != 0");

        // delegate call to an internal function
        _emergencyWithdraw(msg.sender);
    }

    /**
     * @dev Used internally, mostly by children implementations, see emergencyWithdraw()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     */
    function _emergencyWithdraw(
        address _staker
    ) internal virtual {
        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];

        uint256 totalWeight = user.totalWeight ;
        uint256 amount = user.tokenAmount;
        uint256 reward = user.rewardAmount;

        // update user record
        user.tokenAmount = 0;
        user.rewardAmount = 0;
        user.totalWeight = 0;
        user.subYieldRewards = 0;

        // delete entire array directly
        delete user.deposits;

        // update global variable
        usersLockingWeight = usersLockingWeight - totalWeight;

        // just return tokens back to holder
        transferPoolToken(msg.sender, amount - reward);
        // mint the yield via the factory
        factory.mintYieldTo(msg.sender, reward);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     *      updates factory state via `updatehighPerBlock`
     */
    function _sync() internal virtual {
        // update HIGH per block value in factory if required
        if (factory.shouldUpdateRatio()) {
            factory.updateHighPerBlock();
        }

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endBlock = factory.endBlock();
        if (lastYieldDistribution >= endBlock) {
            return;
        }
        if (blockNumber() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (usersLockingWeight == 0) {
            lastYieldDistribution = blockNumber();
            return;
        }

        // to calculate the reward we need to know how many blocks passed, and reward per block
        uint256 currentBlock = blockNumber() > endBlock ? endBlock : blockNumber();
        uint256 blocksPassed = currentBlock - lastYieldDistribution;
        uint256 highPerBlock = factory.highPerBlock();

        // calculate the reward
        uint256 highReward = (blocksPassed * highPerBlock * weight) / factory.totalWeight();

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += rewardToWeight(highReward, usersLockingWeight);
        lastYieldDistribution = currentBlock;

        // emit an event
        emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
     * @return pendingYield the rewards calculated and optionally re-staked
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal virtual returns (uint256 pendingYield) {
        // update smart contract state if required
        if (_withUpdate) {
            _sync();
        }

        // calculate pending yield rewards, this value will be returned
        pendingYield = _pendingYieldRewards(_staker);

        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        if (poolToken == HIGH) {
            // calculate pending yield weight,
            // 2e6 is the bonus weight when staking for 1 year
            uint256 depositWeight = pendingYield * YEAR_STAKE_WEIGHT_MULTIPLIER;

            // if the pool is HIGH Pool - create new HIGH deposit
            // and save it - push it into deposits array
            Deposit memory newDeposit =
                Deposit({
                    tokenAmount: pendingYield,
                    lockedFrom: uint64(now256()),
                    lockedUntil: uint64(now256() + 365 days), // staking yield for 1 year
                    weight: depositWeight,
                    isYield: true
                });
            user.deposits.push(newDeposit);

            // update user record
            user.tokenAmount += pendingYield;
            user.rewardAmount += pendingYield;
            user.totalWeight += depositWeight;

            // update global variable
            usersLockingWeight += depositWeight;
        } else {
            // for other pools - stake as pool
            address highPool = factory.getPoolAddress(HIGH);
            require(highPool != address(0),"invalid high pool address");
            ICorePool(highPool).stakeAsPool(_staker, pendingYield);
        }

        // update users's record for `subYieldRewards` if requested
        if (_withUpdate) {
            user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
        }

        // emit an event
        emit YieldClaimed(msg.sender, _staker, pendingYield);
    }

    /**
     * @dev See updateStakeLock()
     *
     * @param _staker an address to update stake lock
     * @param _depositId updated deposit ID
     * @param _lockedUntil updated deposit locked until value
     */
    function _updateStakeLock(
        address _staker,
        uint256 _depositId,
        uint64 _lockedUntil
    ) internal {
        // validate the input time
        require(_lockedUntil > now256(), "lock should be in the future");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        // validate the input against deposit structure
        require(_lockedUntil > stakeDeposit.lockedUntil, "invalid new lock");

        // verify locked from and locked until values
        if (stakeDeposit.lockedFrom == 0) {
            require(_lockedUntil - now256() <= 365 days, "max lock period is 365 days");
            stakeDeposit.lockedFrom = uint64(now256());
        } else {
            require(_lockedUntil - stakeDeposit.lockedFrom <= 365 days, "max lock period is 365 days");
        }

        // update locked until value, calculate new weight
        stakeDeposit.lockedUntil = _lockedUntil;
        uint256 newWeight =
            (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
                365 days +
                WEIGHT_MULTIPLIER) * stakeDeposit.tokenAmount;

        // save previous weight
        uint256 previousWeight = stakeDeposit.weight;
        // update weight
        stakeDeposit.weight = newWeight;

        // update user total weight and global locking weight
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        // emit an event
        emit StakeLockUpdated(_staker, _depositId, stakeDeposit.lockedFrom, _lockedUntil);
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      HIGH reward value, applying the 10^48 division on weight
     *
     * @param _weight stake weight
     * @param rewardPerWeight HIGH reward per weight
     * @return reward value normalized to 10^48
     */
    function weightToReward(uint256 _weight, uint256 rewardPerWeight) public pure returns (uint256) {
        // apply the formula and return
        return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward HIGH value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward
     *      - OR -
     * @dev Converts reward HIGH value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight
     *
     * @param reward yield reward
     * @param rewardPerWeight reward/weight (or stake weight)
     * @return stake weight (or reward/weight)
     */
    function rewardToWeight(uint256 reward, uint256 rewardPerWeight) public pure returns (uint256) {
        // apply the reverse formula and return
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a pool token
     *
     */
    function transferPoolToken(address _to, uint256 _value) internal {
        SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a pool token
     *
     */
    function transferPoolTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
    }
}