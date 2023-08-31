// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeCast } from "../libraries/SafeCast.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { Timestamp } from "./Timestamp.sol";
import { VaultRecipient } from "./VaultRecipient.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";
import { Stake } from "../libraries/Stake.sol";
import { IILVPool } from "../interfaces/IILVPool.sol";
import { IFactory } from "../interfaces/IFactory.sol";
import { ICorePool } from "../interfaces/ICorePool.sol";
import { ICorePoolV1 } from "../interfaces/ICorePoolV1.sol";

/**
 * @title Core Pool
 *
 * @notice An abstract contract containing common logic for ILV and ILV/ETH SLP pools.
 *
 * @dev Base smart contract for ILV and LP pool. Stores each pool user by mapping
 *      its address to the user struct. User struct stores v2 stakes, which fit
 *      in 1 storage slot each (by using the Stake lib), total weights, pending
 *      yield and revenue distributions, and v1 stake ids. ILV and LP stakes can
 *      be made through flexible stake mode, which only increments the flexible
 *      balance of a given user, or through locked staking. Locked staking creates
 *      a new Stake element fitting 1 storage slot with its value and lock duration.
 *      When calculating pending rewards, CorePool checks v1 locked stakes weights
 *      to increment in the calculations and stores pending yield and pending revenue
 *      distributions. Every time a stake or unstake related function is called,
 *      it updates pending values, but don't require instant claimings. Rewards
 *      claiming are executed in separate functions, and in the case of yield,
 *      it also requires the user checking whether ILV or sILV is wanted as the yield reward.
 *
 * @dev Deployment and initialization.
 *      After proxy is deployed and attached to the implementation, it should be
 *      registered by the PoolFactory contract
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - ILV token address
 *          - sILV token address, used to mint sILV rewards
 *          - pool token address, it can be ILV token address, ILV/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 20% for ILV pool and 80% for ILV/ETH pool initially.
 *      It can be changed through ICCPs and new flash pools added in the protocol.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory).
 * @dev For ILV Pool we use 200 as weight and for ILV/ETH SLP pool - 800.
 *
 */
abstract contract CorePool is
    Initializable,
    UUPSUpgradeable,
    VaultRecipient,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    Timestamp
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using Stake for Stake.Data;
    using ErrorHandler for bytes4;
    using Stake for uint256;

    /// @dev Data structure representing token holder using a pool.
    struct User {
        /// @dev pending yield rewards to be claimed
        uint128 pendingYield;
        /// @dev pending revenue distribution to be claimed
        uint128 pendingRevDis;
        /// @dev Total weight
        uint248 totalWeight;
        /// @dev number of v1StakesIds
        uint8 v1IdsLength;
        /// @dev Checkpoint variable for yield calculation
        uint256 yieldRewardsPerWeightPaid;
        /// @dev Checkpoint variable for vault rewards calculation
        uint256 vaultRewardsPerWeightPaid;
        /// @dev An array of holder's stakes
        Stake.Data[] stakes;
        /// @dev A mapping of holder's stakes ids in V1
        mapping(uint256 => uint256) v1StakesIds;
    }

    /// @dev Data structure used in `unstakeLockedMultiple()` function.
    struct UnstakeParameter {
        uint256 stakeId;
        uint256 value;
    }

    /// @dev Token holder storage, maps token holder address to their data record.
    mapping(address => User) public users;

    /// @dev Maps `keccak256(userAddress,stakeId)` to a uint256 value that tells
    ///      a v1 locked stake weight that has already been migrated to v2
    ///      and is updated through _useV1Weight.
    mapping(address => mapping(uint256 => uint256)) public v1StakesWeights;

    /// @dev Link to sILV ERC20 Token instance.
    address internal _silv;

    /// @dev Link to ILV ERC20 Token instance.
    address internal _ilv;

    /// @dev Address of v1 core pool with same poolToken.
    address internal corePoolV1;

    /// @dev Link to the pool token instance, for example ILV or ILV/ETH pair.
    address public poolToken;

    /// @dev Pool weight, initial values are 200 for ILV pool and 800 for ILV/ETH.
    uint32 public weight;

    /// @dev Timestamp of the last yield distribution event.
    uint64 public lastYieldDistribution;

    /// @dev Used to calculate yield rewards.
    /// @dev This value is different from "reward per token" used in flash pool.
    /// @dev Note: stakes are different in duration and "weight" reflects that.
    uint256 public yieldRewardsPerWeight;

    /// @dev Used to calculate rewards, keeps track of the tokens weight locked in staking.
    uint256 public globalWeight;

    /// @dev Used to calculate rewards, keeps track of the correct token weight in the v1
    ///      core pool.
    uint256 public v1GlobalWeight;

    /// @dev Pool tokens value available in the pool;
    ///      pool token examples are ILV (ILV core pool) or ILV/ETH pair (LP core pool).
    /// @dev For LP core pool this value doesnt' count for ILV tokens received as Vault rewards
    ///      while for ILV core pool it does count for such tokens as well.
    uint256 public poolTokenReserve;

    /// @dev Flag indicating pool type, false means "core pool".
    bool public constant isFlashPool = false;

    /**
     * @dev Fired in _stake() and stakeAsPool() in ILVPool contract.
     * @param by address that executed the stake function (user or pool)
     * @param from token holder address, the tokens will be returned to that address
     * @param stakeId id of the new stake created
     * @param value value of tokens staked
     * @param lockUntil timestamp indicating when tokens should unlock (max 2 years)
     */
    event LogStake(address indexed by, address indexed from, uint256 stakeId, uint256 value, uint64 lockUntil);

    /**
     * @dev Fired in `unstakeLocked()`.
     *
     * @param to address receiving the tokens (user)
     * @param stakeId id value of the stake
     * @param value number of tokens unstaked
     * @param isYield whether stake struct unstaked was coming from yield or not
     */
    event LogUnstakeLocked(address indexed to, uint256 stakeId, uint256 value, bool isYield);

    /**
     * @dev Fired in `unstakeLockedMultiple()`.
     *
     * @param to address receiving the tokens (user)
     * @param totalValue total number of tokens unstaked
     * @param unstakingYield whether unstaked tokens had isYield flag true or false
     */
    event LogUnstakeLockedMultiple(address indexed to, uint256 totalValue, bool unstakingYield);

    /**
     * @dev Fired in `_sync()`, `sync()` and dependent functions (stake, unstake, etc.).
     *
     * @param by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current timestamp
     */
    event LogSync(address indexed by, uint256 yieldRewardsPerWeight, uint64 lastYieldDistribution);

    /**
     * @dev Fired in `_claimYieldRewards()`.
     *
     * @param by an address which claimed the rewards (staker or ilv pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param sILV flag indicating if reward was paid (minted) in sILV
     * @param value value of yield paid
     */
    event LogClaimYieldRewards(address indexed by, address indexed from, bool sILV, uint256 value);

    /**
     * @dev Fired in `_claimVaultRewards()`.
     *
     * @param by an address which claimed the rewards (staker or ilv pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param value value of yield paid
     */
    event LogClaimVaultRewards(address indexed by, address indexed from, uint256 value);

    /**
     * @dev Fired in `_updateRewards()`.
     *
     * @param by an address which processed the rewards (staker or ilv pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param yieldValue value of yield processed
     * @param revDisValue value of revenue distribution processed
     */
    event LogUpdateRewards(address indexed by, address indexed from, uint256 yieldValue, uint256 revDisValue);

    /**
     * @dev fired in `moveFundsFromWallet()`.
     *
     * @param from user asking migration
     * @param to new user address
     * @param previousTotalWeight total weight of `from` before moving to a new address
     * @param newTotalWeight total weight of `to` after moving to a new address
     * @param previousYield pending yield of `from` before moving to a new address
     * @param newYield pending yield of `to` after moving to a new address
     * @param previousRevDis pending revenue distribution of `from` before moving to a new address
     * @param newRevDis pending revenue distribution of `to` after moving to a new address
     */
    event LogMoveFundsFromWallet(
        address indexed from,
        address indexed to,
        uint248 previousTotalWeight,
        uint248 newTotalWeight,
        uint128 previousYield,
        uint128 newYield,
        uint128 previousRevDis,
        uint128 newRevDis
    );

    /**
     * @dev Fired in `receiveVaultRewards()`.
     *
     * @param by an address that sent the rewards, always a vault
     * @param value amount of tokens received
     */
    event LogReceiveVaultRewards(address indexed by, uint256 value);

    /**
     * @dev Used in child contracts to initialize the pool.
     *
     * @param ilv_ ILV ERC20 Token address
     * @param silv_ sILV ERC20 Token address
     * @param _poolToken token the pool operates on, for example ILV or ILV/ETH pair
     * @param _corePoolV1 v1 core pool address
     * @param factory_ PoolFactory contract address
     * @param _initTime initial timestamp used to calculate the rewards
     *      note: _initTime is set to the future effectively meaning _sync() calls will do nothing
     *           before _initTime
     * @param _weight number representing the pool's weight, which in _sync calls
     *        is used by checking the total pools weight in the PoolFactory contract
     */
    function __CorePool_init(
        address ilv_,
        address silv_,
        address _poolToken,
        address _corePoolV1,
        address factory_,
        uint64 _initTime,
        uint32 _weight
    ) internal initializer {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is
        // `bytes4(keccak256("__CorePool_init(address,address,address,address,address,uint64,uint32)"))`
        bytes4 fnSelector = 0x1512be06;
        // verify the inputs
        fnSelector.verifyNonZeroInput(uint160(_poolToken), 2);
        fnSelector.verifyNonZeroInput(uint160(_corePoolV1), 3);
        fnSelector.verifyNonZeroInput(_initTime, 5);
        fnSelector.verifyNonZeroInput(_weight, 6);

        __FactoryControlled_init(factory_);
        __ReentrancyGuard_init();
        __Pausable_init();

        // save the inputs into internal state variables
        _ilv = ilv_;
        _silv = silv_;
        poolToken = _poolToken;
        corePoolV1 = _corePoolV1;
        weight = _weight;

        // init the dependent internal state variables
        lastYieldDistribution = _initTime;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified.
     *
     * @dev See `_pendingRewards()` for further details.
     *
     * @dev External `pendingRewards()` returns pendingYield and pendingRevDis
     *         accumulated with already stored user.pendingYield and user.pendingRevDis.
     *
     * @param _staker an address to calculate yield rewards value for
     */
    function pendingRewards(address _staker)
        external
        view
        virtual
        returns (uint256 pendingYield, uint256 pendingRevDis)
    {
        this.pendingRewards.selector.verifyNonZeroInput(uint160(_staker), 0);
        // `newYieldRewardsPerWeight` will be the stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;
        // gas savings
        uint256 _lastYieldDistribution = lastYieldDistribution;

        // based on the rewards per weight value, calculate pending rewards;
        User storage user = users[_staker];
        // initializes both variables from one storage slot
        (uint256 v1StakesLength, uint256 userWeight) = (uint256(user.v1IdsLength), uint256(user.totalWeight));
        // total user v1 weight to be used
        uint256 totalV1Weight;

        if (v1StakesLength > 0) {
            // loops through v1StakesIds and adds v1 weight
            for (uint256 i = 0; i < v1StakesLength; i++) {
                uint256 stakeId = user.v1StakesIds[i];
                (, uint256 _weight, , , ) = ICorePoolV1(corePoolV1).getDeposit(_staker, stakeId);
                uint256 storedWeight = v1StakesWeights[_staker][stakeId];
                totalV1Weight += _weight <= storedWeight ? _weight : storedWeight;
            }
        }

        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (_now256() > _lastYieldDistribution && globalWeight != 0) {
            uint256 endTime = _factory.endTime();
            uint256 multiplier = _now256() > endTime
                ? endTime - _lastYieldDistribution
                : _now256() - _lastYieldDistribution;
            uint256 ilvRewards = (multiplier * weight * _factory.ilvPerSecond()) / _factory.totalWeight();

            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight =
                ilvRewards.getRewardPerWeight((globalWeight + v1GlobalWeight)) +
                yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        pendingYield =
            (userWeight + totalV1Weight).earned(newYieldRewardsPerWeight, user.yieldRewardsPerWeightPaid) +
            user.pendingYield;
        pendingRevDis =
            (userWeight + totalV1Weight).earned(vaultRewardsPerWeight, user.vaultRewardsPerWeightPaid) +
            user.pendingRevDis;
    }

    /**
     * @notice Returns total staked token balance for the given address.
     * @dev Loops through stakes and returns total balance.
     * @notice Expected to be called externally through `eth_call`. Gas shouldn't
     *         be an issue here.
     *
     * @param _user an address to query balance for
     * @return balance total staked token balance
     */
    function balanceOf(address _user) external view virtual returns (uint256 balance) {
        // gets storage pointer to _user
        User storage user = users[_user];
        // loops over each user stake and adds to the total balance.
        for (uint256 i = 0; i < user.stakes.length; i++) {
            balance += user.stakes[i].value;
        }
    }

    /**
     * @dev Returns the sum of poolTokenReserve with the deposit reserves in v1.
     * @dev In ILV Pool contract the eDAO stores the v1 reserve value, and
     *      in the SLP pool we're able to query it from the v1 lp pool contract.
     */
    function getTotalReserves() external view virtual returns (uint256 totalReserves);

    /**
     * @notice Returns information on the given stake for the given address.
     *
     * @dev See getStakesLength.
     *
     * @param _user an address to query stake for
     * @param _stakeId zero-indexed stake ID for the address specified
     * @return stake info as Stake structure
     */
    function getStake(address _user, uint256 _stakeId) external view virtual returns (Stake.Data memory) {
        // read stake at specified index and return
        return users[_user].stakes[_stakeId];
    }

    /**
     * @notice Returns a v1 stake id in the `user.v1StakesIds` array.
     *
     * @dev Get v1 stake id position through `getV1StakePosition()`.
     *
     * @param _user an address to query stake for
     * @param _position position index in the array
     * @return stakeId value
     */
    function getV1StakeId(address _user, uint256 _position) external view virtual returns (uint256) {
        // returns the v1 stake id indicated at _position value
        return users[_user].v1StakesIds[_position];
    }

    /**
     * @notice Returns a v1 stake position in the `user.v1StakesIds` array.
     *
     * @dev Helper function to call `getV1StakeId()`.
     * @dev Reverts if stakeId isn't found.
     *
     * @param _user an address to query stake for
     * @param _desiredId desired stakeId position in the array to find
     * @return position stake info as Stake structure
     */
    function getV1StakePosition(address _user, uint256 _desiredId) external view virtual returns (uint256 position) {
        // gets storage pointer to user
        User storage user = users[_user];

        // loops over each v1 stake id and checks if it's the one
        // that the caller is looking for
        for (uint256 i = 0; i < user.v1IdsLength; i++) {
            if (user.v1StakesIds[i] == _desiredId) {
                // if it's the desired stake id, return the array index (i.e position)
                return i;
            }
        }

        revert();
    }

    /**
     * @notice Returns number of stakes for the given address. Allows iteration over stakes.
     *
     * @dev See `getStake()`.
     *
     * @param _user an address to query stake length for
     * @return number of stakes for the given address
     */
    function getStakesLength(address _user) external view virtual returns (uint256) {
        // read stakes array length and return
        return users[_user].stakes.length;
    }

    /**
     * @dev Set paused/unpaused state in the pool contract.
     *
     * @param _shouldPause whether the contract should be paused/unpausd
     */
    function pause(bool _shouldPause) external {
        // checks if caller is authorized to pause
        _requireIsFactoryController();
        // checks bool input and pause/unpause the contract depending on
        // msg.sender's request
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Stakes specified value of tokens for the specified value of time,
     *      and pays pending yield rewards if any.
     *
     * @dev Requires value to stake and lock duration to be greater than zero.
     *
     * @param _value value of tokens to stake
     * @param _lockDuration stake duration as unix timestamp
     */
    function stake(uint256 _value, uint64 _lockDuration) external virtual nonReentrant {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.stake.selector;
        // validate the inputs
        fnSelector.verifyNonZeroInput(_value, 1);
        fnSelector.verifyInput(_lockDuration >= Stake.MIN_STAKE_PERIOD && _lockDuration <= Stake.MAX_STAKE_PERIOD, 2);

        // get a link to user data struct, we will write to it later
        User storage user = users[msg.sender];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // update user state
        _updateReward(msg.sender, v1WeightToAdd);

        // calculates until when a stake is going to be locked
        uint64 lockUntil = (_now256()).toUint64() + _lockDuration;
        // stake weight formula rewards for locking
        uint256 stakeWeight = (((lockUntil - _now256()) * Stake.WEIGHT_MULTIPLIER) /
            Stake.MAX_STAKE_PERIOD +
            Stake.BASE_WEIGHT) * _value;
        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);
        // create and save the stake (append it to stakes array)
        Stake.Data memory userStake = Stake.Data({
            value: (_value).toUint120(),
            lockedFrom: (_now256()).toUint64(),
            lockedUntil: lockUntil,
            isYield: false
        });
        // pushes new stake to `stakes` array
        user.stakes.push(userStake);
        // update user weight
        user.totalWeight += (stakeWeight).toUint248();
        // update global weight value and global pool token count
        globalWeight += stakeWeight;
        poolTokenReserve += _value;

        // transfer `_value`
        IERC20Upgradeable(poolToken).safeTransferFrom(address(msg.sender), address(this), _value);

        // emit an event
        emit LogStake(msg.sender, msg.sender, (user.stakes.length - 1), _value, lockUntil);
    }

    /**
     * @dev Moves msg.sender stake data to a new address.
     * @dev V1 stakes are never migrated to the new address. We process all rewards,
     *      clean the previous user (msg.sender), add the previous user data to
     *      the desired address and update subYieldRewards/subVaultRewards values
     *      in order to make sure both addresses will have rewards cleaned.
     *
     * @param _to new user address, needs to be a fresh address with no stakes
     */

    function moveFundsFromWallet(address _to) public virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // gets storage pointer to msg.sender user struct
        User storage previousUser = users[msg.sender];
        // gets storage pointer to desired address user struct
        User storage newUser = users[_to];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // We process update global and user's rewards
        // before moving the user funds to a new wallet.
        // This way we can ensure that all v1 ids weight have been used before the v2
        // stakes to a new address.
        _updateReward(msg.sender, v1WeightToAdd);

        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.moveFundsFromWallet.selector;
        // validate input is set
        fnSelector.verifyNonZeroInput(uint160(_to), 0);
        // verify new user records are empty
        fnSelector.verifyState(
            newUser.totalWeight == 0 &&
                newUser.v1IdsLength == 0 &&
                newUser.stakes.length == 0 &&
                newUser.yieldRewardsPerWeightPaid == 0 &&
                newUser.vaultRewardsPerWeightPaid == 0,
            0
        );
        // saves previous user total weight
        uint248 previousTotalWeight = previousUser.totalWeight;
        // saves previous user pending yield
        uint128 previousYield = previousUser.pendingYield;
        // saves previous user pending rev dis
        uint128 previousRevDis = previousUser.pendingRevDis;

        // It's expected to have all previous user values
        // migrated to the new user address (_to).
        // We recalculate yield and vault rewards values
        // to make sure new user pending yield and pending rev dis to be stored
        // at newUser.pendingYield and newUser.pendingRevDis is 0, since we just processed
        // all pending rewards calling _updateReward.
        newUser.totalWeight = previousTotalWeight;
        newUser.pendingYield = previousYield;
        newUser.pendingRevDis = previousRevDis;
        newUser.yieldRewardsPerWeightPaid = yieldRewardsPerWeight;
        newUser.vaultRewardsPerWeightPaid = vaultRewardsPerWeight;
        newUser.stakes = previousUser.stakes;
        delete previousUser.totalWeight;
        delete previousUser.pendingYield;
        delete previousUser.pendingRevDis;
        delete previousUser.stakes;

        // emits an event
        emit LogMoveFundsFromWallet(
            msg.sender,
            _to,
            previousTotalWeight,
            newUser.totalWeight,
            previousYield,
            newUser.pendingYield,
            previousRevDis,
            newUser.pendingRevDis
        );
    }

    /**
     * @notice Service function to synchronize pool state with current time.
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one second passes between synchronizations.
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract.
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end time), function doesn't throw and exits silently.
     */
    function sync() external virtual {
        _requireNotPaused();
        // calls internal function
        _sync();
    }

    /**
     * @dev Calls internal `_claimYieldRewards()` passing `msg.sender` as `_staker`.
     *
     * @notice Pool state is updated before calling the internal function.
     */
    function claimYieldRewards(bool _useSILV) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal function
        _claimYieldRewards(msg.sender, _useSILV);
    }

    /**
     * @dev Calls internal `_claimVaultRewards()` passing `msg.sender` as `_staker`.
     *
     * @notice Pool state is updated before calling the internal function.
     */
    function claimVaultRewards() external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal function
        _claimVaultRewards(msg.sender);
    }

    /**
     * @dev Claims both revenue distribution and yield rewards in one call.
     *
     */
    function claimAllRewards(bool _useSILV) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal yield and vault rewards functions
        _claimVaultRewards(msg.sender);
        _claimYieldRewards(msg.sender, _useSILV);
    }

    /**
     * @dev Executed by the vault to transfer vault rewards ILV from the vault
     *      into the pool.
     *
     * @dev This function is executed only for ILV core pools.
     *
     * @param _value amount of ILV rewards to transfer into the pool
     */
    function receiveVaultRewards(uint256 _value) external virtual {
        // always sync the pool state vars before moving forward
        _sync();
        // checks if the contract is in a paused state
        _requireNotPaused();
        // checks if msg.sender is the vault contract
        _requireIsVault();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.receiveVaultRewards.selector;
        // return silently if there is no reward to receive
        if (_value == 0) {
            return;
        }
        // verify weight is not zero
        fnSelector.verifyState(globalWeight > 0 || v1GlobalWeight > 0, 0);
        // we update vaultRewardsPerWeight value using v1 and v2 global weight,
        // expecting to distribute revenue distribution correctly to all users
        // coming from v1 and new v2 users.
        vaultRewardsPerWeight += _value.getRewardPerWeight(globalWeight + v1GlobalWeight);

        // transfers ILV from the Vault contract to the pool
        IERC20Upgradeable(_ilv).safeTransferFrom(msg.sender, address(this), _value);

        // emits an event
        emit LogReceiveVaultRewards(msg.sender, _value);
    }

    /**
     * @dev Updates value that keeps track of v1 global locked tokens weight.
     *
     * @param _v1GlobalWeight new value to be stored
     */
    function setV1GlobalWeight(uint256 _v1GlobalWeight) external virtual {
        // only factory controller can update the _v1GlobalWeight
        _requireIsFactoryController();

        // update v1GlobalWeight state variable
        v1GlobalWeight = _v1GlobalWeight;
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating.
     *
     * @dev Set weight to zero to disable the pool.
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint32 _weight) external virtual {
        // update pool state using current weight value
        _sync();
        // verify function is executed by the factory
        this.setWeight.selector.verifyAccess(msg.sender == address(_factory));

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Unstakes a stake that has been previously locked, and is now in an unlocked
     *      state. If the stake has the isYield flag set to true, then the contract
     *      requests ILV to be minted by the PoolFactory. Otherwise it transfers ILV or LP
     *      from the contract balance.
     *
     * @param _stakeId stake ID to unstake from, zero-indexed
     * @param _value value of tokens to unstake
     */
    function unstake(uint256 _stakeId, uint256 _value) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.unstake.selector;

        // verify a value is set
        fnSelector.verifyNonZeroInput(_value, 0);
        // get a link to user data struct, we will write to it later
        User storage user = users[msg.sender];
        // get a link to the corresponding stake, we may write to it later
        Stake.Data storage userStake = user.stakes[_stakeId];
        // checks if stake is unlocked already
        fnSelector.verifyState(_now256() > userStake.lockedUntil, 0);
        // stake structure may get deleted, so we save isYield flag to be able to use it
        // we also save stakeValue for gasSavings
        (uint120 stakeValue, bool isYield) = (userStake.value, userStake.isYield);
        // verify available balance
        fnSelector.verifyInput(stakeValue >= _value, 1);
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // and process current pending rewards if any
        _updateReward(msg.sender, v1WeightToAdd);
        // store stake weight
        uint256 previousWeight = userStake.weight();
        // value used to save new weight after updates in storage
        uint256 newWeight;

        // update the stake, or delete it if its depleted
        if (stakeValue - _value == 0) {
            // deletes stake struct, no need to save new weight because it stays 0
            delete user.stakes[_stakeId];
        } else {
            userStake.value -= (_value).toUint120();
            // saves new weight to memory
            newWeight = userStake.weight();
        }
        // update user record
        user.totalWeight = uint248(user.totalWeight - previousWeight + newWeight);
        // update global weight variable
        globalWeight = globalWeight - previousWeight + newWeight;
        // update global pool token count
        poolTokenReserve -= _value;

        // if the stake was created by the pool itself as a yield reward
        if (isYield) {
            // mint the yield via the factory
            _factory.mintYieldTo(msg.sender, _value, false);
        } else {
            // otherwise just return tokens back to holder
            IERC20Upgradeable(poolToken).safeTransfer(msg.sender, _value);
        }

        // emits an event
        emit LogUnstakeLocked(msg.sender, _stakeId, _value, isYield);
    }

    /**
     * @dev Executes unstake on multiple stakeIds. See `unstakeLocked()`.
     * @dev Optimizes gas by requiring all unstakes to be made either in yield stakes
     *      or in non yield stakes. That way we can transfer or mint tokens in one call.
     *
     * @notice User is required to either mint ILV or unstake pool tokens in the function call.
     *         There's no way to do both operations in one call.
     *
     * @param _stakes array of stakeIds and values to be unstaked in each stake from
     *                the msg.sender
     * @param _unstakingYield whether all stakeIds have isYield flag set to true or false,
     *                        i.e if we're minting ILV or transferring pool tokens
     */
    function unstakeMultiple(UnstakeParameter[] calldata _stakes, bool _unstakingYield) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.unstakeMultiple.selector;
        // verifies if user has passed any value to be unstaked
        fnSelector.verifyNonZeroInput(_stakes.length, 0);
        // gets storage pointer to the user
        User storage user = users[msg.sender];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        _updateReward(msg.sender, v1WeightToAdd);

        // initialize variables that expect to receive the total
        // weight to be removed from the user and the value to be
        // unstaked from the pool.
        uint256 weightToRemove;
        uint256 valueToUnstake;

        for (uint256 i = 0; i < _stakes.length; i++) {
            // destructure calldata parameters
            (uint256 _stakeId, uint256 _value) = (_stakes[i].stakeId, _stakes[i].value);
            Stake.Data storage userStake = user.stakes[_stakeId];
            // checks if stake is unlocked already
            fnSelector.verifyState(_now256() > userStake.lockedUntil, i * 3);
            // checks if unstaking value is valid
            fnSelector.verifyNonZeroInput(_value, 1);
            // stake structure may get deleted, so we save isYield flag to be able to use it
            // we also save stakeValue for gas savings
            (uint120 stakeValue, bool isYield) = (userStake.value, userStake.isYield);
            // verifies if the selected stake is yield (i.e ILV to be minted)
            // or not, the function needs to either mint yield or transfer tokens
            // and can't do both operations at the same time.
            fnSelector.verifyState(isYield == _unstakingYield, i * 3 + 1);
            // checks if there's enough tokens to unstake
            fnSelector.verifyState(stakeValue >= _value, i * 3 + 2);

            // store stake weight
            uint256 previousWeight = userStake.weight();
            // value used to save new weight after updates in storage
            uint256 newWeight;

            // update the stake, or delete it if its depleted
            if (stakeValue - _value == 0) {
                // deletes stake struct, no need to save new weight because it stays 0
                delete user.stakes[_stakeId];
            } else {
                // removes _value from the stake with safe cast
                userStake.value -= (_value).toUint120();
                // saves new weight to memory
                newWeight = userStake.weight();
            }

            // updates the values initialized earlier with the amounts that
            // need to be subtracted (weight) and transferred (value to unstake)
            weightToRemove += previousWeight - newWeight;
            valueToUnstake += _value;
        }
        // subtracts weight
        user.totalWeight -= (weightToRemove).toUint248();
        // update global variable
        globalWeight -= weightToRemove;
        // update pool token count
        poolTokenReserve -= valueToUnstake;

        // if the stake was created by the pool itself as a yield reward
        if (_unstakingYield) {
            // mint the yield via the factory
            _factory.mintYieldTo(msg.sender, valueToUnstake, false);
        } else {
            // otherwise just return tokens back to holder
            IERC20Upgradeable(poolToken).safeTransfer(msg.sender, valueToUnstake);
        }

        // emits an event
        emit LogUnstakeLockedMultiple(msg.sender, valueToUnstake, _unstakingYield);
    }

    /**
     * @dev Used internally, mostly by children implementations, see `sync()`.
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     *      updates factory state via `updateILVPerSecond`
     */
    function _sync() internal virtual {
        // gas savings
        IFactory factory_ = _factory;
        // update ILV per second value in factory if required
        if (factory_.shouldUpdateRatio()) {
            factory_.updateILVPerSecond();
        }

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endTime = factory_.endTime();
        if (lastYieldDistribution >= endTime) {
            return;
        }
        if (_now256() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (globalWeight == 0 && v1GlobalWeight == 0) {
            lastYieldDistribution = (_now256()).toUint64();
            return;
        }

        // to calculate the reward we need to know how many seconds passed, and reward per second
        uint256 currentTimestamp = _now256() > endTime ? endTime : _now256();
        uint256 secondsPassed = currentTimestamp - lastYieldDistribution;
        uint256 ilvPerSecond = factory_.ilvPerSecond();

        // calculate the reward
        uint256 ilvReward = (secondsPassed * ilvPerSecond * weight) / factory_.totalWeight();

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += ilvReward.getRewardPerWeight((globalWeight + v1GlobalWeight));
        lastYieldDistribution = (currentTimestamp).toUint64();

        // emit an event
        emit LogSync(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    /**
     * @dev claims all pendingYield from _staker using ILV or sILV.
     *
     * @notice sILV is minted straight away to _staker wallet, ILV is created as
     *         a new stake and locked for Stake.MAX_STAKE_PERIOD.
     *
     * @param _staker user address
     * @param _useSILV whether the user wants to claim ILV or sILV
     */
    function _claimYieldRewards(address _staker, bool _useSILV) internal virtual {
        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(_staker);
        // update user state
        _updateReward(_staker, v1WeightToAdd);
        // check pending yield rewards to claim and save to memory
        uint256 pendingYieldToClaim = uint256(user.pendingYield);
        // if pending yield is zero - just return silently
        if (pendingYieldToClaim == 0) return;
        // clears user pending yield
        user.pendingYield = 0;

        // if sILV is requested
        if (_useSILV) {
            // - mint sILV
            _factory.mintYieldTo(_staker, pendingYieldToClaim, true);
        } else if (poolToken == _ilv) {
            // calculate pending yield weight,
            // 2e6 is the bonus weight when staking for 1 year
            uint256 stakeWeight = pendingYieldToClaim * Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;

            // if the pool is ILV Pool - create new ILV stake
            // and save it - push it into stakes array
            Stake.Data memory newStake = Stake.Data({
                value: (pendingYieldToClaim).toUint120(),
                lockedFrom: (_now256()).toUint64(),
                lockedUntil: (_now256() + Stake.MAX_STAKE_PERIOD).toUint64(), // staking yield for 1 year
                isYield: true
            });
            // add memory stake to storage
            user.stakes.push(newStake);
            // updates total user weight with the newly created stake's weight
            user.totalWeight += (stakeWeight).toUint248();

            // update global variable
            globalWeight += stakeWeight;
            // update reserve count
            poolTokenReserve += pendingYieldToClaim;
        } else {
            // for other pools - stake as pool
            address ilvPool = _factory.getPoolAddress(_ilv);
            IILVPool(ilvPool).stakeAsPool(_staker, pendingYieldToClaim);
        }

        // emits an event
        emit LogClaimYieldRewards(msg.sender, _staker, _useSILV, pendingYieldToClaim);
    }

    /**
     * @dev Claims all pendingRevDis from _staker using ILV.
     * @dev ILV is sent straight away to _staker address.
     *
     * @param _staker user address
     */
    function _claimVaultRewards(address _staker) internal virtual {
        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(_staker);
        // update user state
        _updateReward(_staker, v1WeightToAdd);
        // check pending yield rewards to claim and save to memory
        uint256 pendingRevDis = uint256(user.pendingRevDis);
        // if pending yield is zero - just return silently
        if (pendingRevDis == 0) return;
        // clears user pending revenue distribution
        user.pendingRevDis = 0;

        IERC20Upgradeable(_ilv).safeTransfer(_staker, pendingRevDis);

        // emits an event
        emit LogClaimVaultRewards(msg.sender, _staker, pendingRevDis);
    }

    /**
     * @dev Calls CorePoolV1 contract, gets v1 stake ids weight and returns.
     * @dev Used by `_pendingRewards()` to calculate yield and revenue distribution
     *      rewards taking v1 weights into account.
     *
     * @notice If v1 weights have changed since last call, we use latest v1 weight for
     *         yield and revenue distribution rewards calculations, and recalculate
     *         user sub rewards values in order to have correct rewards estimations.
     *
     * @param _staker user address passed
     *
     * @return totalV1Weight uint256 value of v1StakesIds weights
     */
    function _useV1Weight(address _staker) internal virtual returns (uint256 totalV1Weight) {
        // gets user storage pointer
        User storage user = users[_staker];
        // gas savings
        uint256 v1StakesLength = user.v1IdsLength;

        // checks if user has any migrated stake from v1
        if (v1StakesLength > 0) {
            // loops through v1StakesIds and adds v1 weight
            for (uint256 i = 0; i < v1StakesLength; i++) {
                // saves v1 stake id to memory
                uint256 stakeId = user.v1StakesIds[i];
                (, uint256 _weight, , , ) = ICorePoolV1(corePoolV1).getDeposit(_staker, stakeId);

                // gets weight stored initially in the v1StakesWeights mapping
                // through V2Migrator contract
                uint256 storedWeight = v1StakesWeights[_staker][stakeId];
                // only stores the current v1 weight that is going to be used for calculations
                // if current v1 weight is equal to or less than the stored weight.
                // This way we make sure that v1 weight never increases for any reason
                // (e.g increasing a v1 stake lock through v1 contract) and messes up calculations.
                totalV1Weight += _weight <= storedWeight ? _weight : storedWeight;

                // if _weight has updated in v1 to a lower value, we also update
                // stored weight in v2 for next calculations
                if (storedWeight > _weight) {
                    // if deposit has been completely unstaked in v1, set stake id weight to 1
                    // so we can keep track that it has been already migrated.
                    // otherwise just update value to _weight
                    v1StakesWeights[_staker][stakeId] = _weight == 0 ? 1 : _weight;
                }
            }
        }
    }

    /**
     * @dev Checks if pool is paused.
     * @dev We use this internal function instead of the modifier coming from
     *      Pausable contract in order to decrease contract's bytecode size.
     */
    function _requireNotPaused() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requireNotPaused()"))`
        bytes4 fnSelector = 0xabb87a6f;
        // checks paused variable value from Pausable Open Zeppelin
        fnSelector.verifyState(!paused(), 0);
    }

    /**
     * @dev Must be called every time user.totalWeight is changed.
     * @dev Syncs the global pool state, processes the user pending rewards (if any),
     *      and updates check points values stored in the user struct.
     * @dev If user is coming from v1 pool, it expects to receive this v1 user weight
     *      to include in rewards calculations.
     *
     * @param _staker user address
     * @param _v1WeightToAdd v1 weight to be added to calculations
     */
    function _updateReward(address _staker, uint256 _v1WeightToAdd) internal virtual {
        // update pool state
        _sync();
        // gets storage reference to the user
        User storage user = users[_staker];
        // gas savings
        uint256 userTotalWeight = uint256(user.totalWeight) + _v1WeightToAdd;

        // calculates pending yield to be added
        uint256 pendingYield = userTotalWeight.earned(yieldRewardsPerWeight, user.yieldRewardsPerWeightPaid);
        // calculates pending reenue distribution to be added
        uint256 pendingRevDis = userTotalWeight.earned(vaultRewardsPerWeight, user.vaultRewardsPerWeightPaid);
        // increases stored user.pendingYield with value returned
        user.pendingYield += pendingYield.toUint128();
        // increases stored user.pendingRevDis with value returned
        user.pendingRevDis += pendingRevDis.toUint128();

        // updates user checkpoint values for future calculations
        user.yieldRewardsPerWeightPaid = yieldRewardsPerWeight;
        user.vaultRewardsPerWeightPaid = vaultRewardsPerWeight;

        // emit an event
        emit LogUpdateRewards(msg.sender, _staker, pendingYield, pendingRevDis);
    }

    /**
     * @dev See UUPSUpgradeable `_authorizeUpgrade()`.
     * @dev Just checks if `msg.sender` == `factory.owner()` i.e eDAO multisig address.
     * @dev eDAO multisig is responsible by handling upgrades and executing other
     *      admin actions approved by the Council.
     */
    function _authorizeUpgrade(address) internal view virtual override {
        // checks caller is factory.owner()
        _requireIsFactoryController();
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[39] private __gap;
}