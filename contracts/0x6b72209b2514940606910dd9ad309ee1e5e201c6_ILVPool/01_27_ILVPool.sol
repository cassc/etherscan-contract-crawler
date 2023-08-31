// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeCast } from "./libraries/SafeCast.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { V2Migrator } from "./base/V2Migrator.sol";
import { CorePool } from "./base/CorePool.sol";
import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { Stake } from "./libraries/Stake.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { ICorePool } from "./interfaces/ICorePool.sol";
import { ICorePoolV1 } from "./interfaces/ICorePoolV1.sol";
import { SushiLPPool } from "./SushiLPPool.sol";

/**
 * @title ILV Pool
 *
 * @dev ILV Pool contract to be deployed, with all base contracts inherited.
 * @dev Extends functionality working as a router to SushiLP Pool and deployed flash pools.
 *      through functions like `claimYieldRewardsMultiple()` and `claimVaultRewardsMultiple()`,
 *      ILV Pool is trusted by other pools and verified by the factory to aggregate functions
 *      and add quality of life features for stakers.
 */
contract ILVPool is Initializable, V2Migrator {
    using ErrorHandler for bytes4;
    using Stake for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using BitMaps for BitMaps.BitMap;

    /// @dev stores merkle root related to users yield weight in v1.
    bytes32 public merkleRoot;

    /// @dev bitmap mapping merkle tree user indexes to a bit that tells
    ///      whether a user has already migrated yield or not.
    BitMaps.BitMap internal _usersMigrated;

    /// @dev maps `keccak256(userAddress,stakeId)` to a bool value that tells
    ///      if a v1 yield has already been minted by v2 contract.
    mapping(address => mapping(uint256 => bool)) public v1YieldMinted;

    /// @dev Used to calculate vault (revenue distribution) rewards, keeps track
    ///      of the correct ILV balance in the v1 core pool.
    uint256 public v1PoolTokenReserve;

    /**
     * @dev logs `_migratePendingRewards()`
     *
     * @param from user address
     * @param pendingRewardsMigrated value of pending rewards migrated
     * @param useSILV whether user claimed v1 pending rewards as ILV or sILV
     */
    event LogMigratePendingRewards(address indexed from, uint256 pendingRewardsMigrated, bool useSILV);

    /**
     * @dev logs `_migrateYieldWeights()`
     *
     * @param from user address
     * @param yieldWeightMigrated total amount of weight coming from yield in v1
     *
     */
    event LogMigrateYieldWeight(address indexed from, uint256 yieldWeightMigrated);

    /**
     * @dev logs `mintV1YieldMultiple()`.
     *
     * @param from user address
     * @param value number of ILV tokens minted
     *
     */
    event LogV1YieldMintedMultiple(address indexed from, uint256 value);

    /// @dev Calls `__V2Migrator_init()`.
    function initialize(
        address ilv_,
        address silv_,
        address _poolToken,
        address factory_,
        uint64 _initTime,
        uint32 _weight,
        address _corePoolV1,
        uint256 v1StakeMaxPeriod_
    ) external initializer {
        // calls internal v2 migrator initializer
        __V2Migrator_init(ilv_, silv_, _poolToken, _corePoolV1, factory_, _initTime, _weight, v1StakeMaxPeriod_);
    }

    /**
     * @dev Updates value that keeps track of v1 global locked tokens weight.
     *
     * @param _v1PoolTokenReserve new value to be stored
     */
    function setV1PoolTokenReserve(uint256 _v1PoolTokenReserve) external virtual {
        // only factory controller can update the _v1GlobalWeight
        _requireIsFactoryController();

        // update v1PoolTokenReserve state variable
        v1PoolTokenReserve = _v1PoolTokenReserve;
    }

    /// @inheritdoc CorePool
    function getTotalReserves() external view virtual override returns (uint256 totalReserves) {
        totalReserves = poolTokenReserve + v1PoolTokenReserve;
    }

    /**
     * @dev Sets the yield weight tree root.
     * @notice Can only be called by the eDAO.
     *
     * @param _merkleRoot 32 bytes tree root.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external virtual {
        // checks if function is being called by PoolFactory.owner()
        _requireIsFactoryController();
        // stores the merkle root
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Returns whether an user of a given _index in the bitmap has already
     *      migrated v1 yield weight stored in the merkle tree or not.
     *
     * @param _index user index in the bitmap, can be checked in the off-chain
     *               merkle tree
     * @return whether user has already migrated yield weights or not
     */
    function hasMigratedYield(uint256 _index) public view returns (bool) {
        // checks if the merkle tree index linked to a user address has a bit of
        // value 0 or 1
        return _usersMigrated.get(_index);
    }

    /**
     * @dev Executed by other core pools and flash pools
     *      as part of yield rewards processing logic (`_claimYieldRewards()` function).
     * @dev Executed when _useSILV is false and pool is not an ILV pool -
     *      see `CorePool._processRewards()`.
     *
     * @param _staker an address which stakes (the yield reward)
     * @param _value amount to be staked (yield reward amount)
     */
    function stakeAsPool(address _staker, uint256 _value) external nonReentrant {
        // checks if contract is paused
        _requireNotPaused();
        // expects caller to be a valid contract registered by the pool factory
        this.stakeAsPool.selector.verifyAccess(_factory.poolExists(msg.sender));
        // gets storage pointer to user
        User storage user = users[_staker];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(_staker);
        // update user state
        _updateReward(_staker, v1WeightToAdd);
        // calculates take weight based on how much yield has been generated
        // (by checking _value) and multiplies by the 2e6 constant, since
        // yield is always locked for a year.
        uint256 stakeWeight = _value * Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;
        // initialize new yield stake being created in memory
        Stake.Data memory newStake = Stake.Data({
            value: (_value).toUint120(),
            lockedFrom: (_now256()).toUint64(),
            lockedUntil: (_now256() + Stake.MAX_STAKE_PERIOD).toUint64(),
            isYield: true
        });
        // sum new yield stake weight to user's total weight
        user.totalWeight += (stakeWeight).toUint248();
        // add the new yield stake to storage
        user.stakes.push(newStake);
        // update global weight and global pool token count
        globalWeight += stakeWeight;
        poolTokenReserve += _value;

        // emits an event
        emit LogStake(
            msg.sender,
            _staker,
            (user.stakes.length - 1),
            _value,
            (_now256() + Stake.MAX_STAKE_PERIOD).toUint64()
        );
    }

    /**
     * @dev Calls internal `_migrateLockedStakes`,  `_migrateYieldWeights`
     *      and `_migratePendingRewards` functions for a complete migration
     *      of a v1 user to v2.
     * @dev See `_migrateLockedStakes` and _`migrateYieldWeights`.
     */
    function executeMigration(
        bytes32[] calldata _proof,
        uint256 _index,
        uint248 _yieldWeight,
        uint256 _pendingV1Rewards,
        bool _useSILV,
        uint256[] calldata _stakeIds
    ) external virtual {
        // verifies that user isn't a v1 blacklisted user
        _requireNotBlacklisted(msg.sender);
        // checks if contract is paused
        _requireNotPaused();

        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // update user state
        _updateReward(msg.sender, v1WeightToAdd);
        // call internal migrate locked stake function
        // which does the loop to store each v1 stake
        // reference in v2 and all required data
        _migrateLockedStakes(_stakeIds);
        // checks if user is also migrating the v1 yield accumulated weight
        if (_yieldWeight > 0) {
            // if that's the case, passes the merkle proof with the user index
            // in the merkle tree, and the yield weight being migrated
            // which will be verified, and then update user state values by the
            // internal function
            _migrateYieldWeights(_proof, _index, _yieldWeight, _pendingV1Rewards, _useSILV);
        }
    }

    /**
     * @dev Calls multiple pools claimYieldRewardsFromRouter() in order to claim yield
     * in 1 transaction.
     *
     * @notice ILV pool works as a router for claiming multiple pools registered
     *         in the factory.
     *
     * @param _pools array of pool addresses
     * @param _useSILV array of bool values telling if the pool should claim reward
     *                 as ILV or sILV
     */
    function claimYieldRewardsMultiple(address[] calldata _pools, bool[] calldata _useSILV) external virtual {
        // checks if contract is paused
        _requireNotPaused();

        // we're using selector to simplify input and access validation
        bytes4 fnSelector = this.claimYieldRewardsMultiple.selector;
        // checks if user passed the correct number of inputs
        fnSelector.verifyInput(_pools.length == _useSILV.length, 0);
        // loops over each pool passed to execute the necessary checks, and call
        // the functions according to the pool
        for (uint256 i = 0; i < _pools.length; i++) {
            // gets current pool in the loop
            address pool = _pools[i];
            // verifies that the given pool is a valid pool registered by the pool
            // factory contract
            fnSelector.verifyAccess(IFactory(_factory).poolExists(pool));
            // if the pool passed is the ILV pool (i.e this contract),
            // just calls an internal function
            if (ICorePool(pool).poolToken() == _ilv) {
                // call internal _claimYieldRewards
                _claimYieldRewards(msg.sender, _useSILV[i]);
            } else {
                // if not, executes a calls to the other core pool which will handle
                // the other pool reward claim
                SushiLPPool(pool).claimYieldRewardsFromRouter(msg.sender, _useSILV[i]);
            }
        }
    }

    /**
     * @dev Calls multiple pools claimVaultRewardsFromRouter() in order to claim yield
     * in 1 transaction.
     *
     * @notice ILV pool works as a router for claiming multiple pools registered
     *         in the factory
     *
     * @param _pools array of pool addresses
     */
    function claimVaultRewardsMultiple(address[] calldata _pools) external virtual {
        // checks if contract is paused
        _requireNotPaused();
        // loops over each pool passed to execute the necessary checks, and call
        // the functions according to the pool
        for (uint256 i = 0; i < _pools.length; i++) {
            // gets current pool in the loop
            address pool = _pools[i];
            // we're using selector to simplify input and state validation
            // checks if the given pool is a valid one registred by the pool
            // factory contract
            this.claimVaultRewardsMultiple.selector.verifyAccess(IFactory(_factory).poolExists(pool));
            // if the pool passed is the ILV pool (i.e this contract),
            // just calls an internal function
            if (ICorePool(pool).poolToken() == _ilv) {
                // call internal _claimVaultRewards
                _claimVaultRewards(msg.sender);
            } else {
                // if not, executes a calls to the other core pool which will handle
                // the other pool reward claim
                SushiLPPool(pool).claimVaultRewardsFromRouter(msg.sender);
            }
        }
    }

    /**
     * @dev Aggregates in one single mint call multiple yield stakeIds from v1.
     * @dev reads v1 ILV pool to execute checks, if everything is correct, it stores
     *      in memory total amount of yield to be minted and calls the PoolFactory to mint
     *      it to msg.sender.
     *
     * @notice V1 won't be able to mint ILV yield anymore. This mean only this function
     *         in the V2 contract is able to mint previously accumulated V1 yield.
     *
     * @param _stakeIds array of yield ids in v1 from msg.sender user
     */
    function mintV1YieldMultiple(uint256[] calldata _stakeIds) external virtual {
        // we're using function selector to simplify validation
        bytes4 fnSelector = this.mintV1YieldMultiple.selector;
        // verifies that user isn't a v1 blacklisted user
        _requireNotBlacklisted(msg.sender);
        // checks if contract is paused
        _requireNotPaused();
        // gets storage pointer to the user
        User storage user = users[msg.sender];
        // initialize variables that will be used inside the loop
        // to store how much yield needs to be minted and how much
        // weight needs to be removed from the user
        uint256 amountToMint;
        uint256 weightToRemove;

        // initializes variable that will store how much v1 weight the user has
        uint256 v1WeightToAdd;

        // avoids stack too deep error
        {
            // uses v1 weight values for rewards calculations
            uint256 _v1WeightToAdd = _useV1Weight(msg.sender);
            // update user state
            _updateReward(msg.sender, _v1WeightToAdd);

            v1WeightToAdd = _v1WeightToAdd;
        }

        // loops over each stake id, doing the necessary checks and
        // updating the mapping that keep tracks of v1 yield mints.
        for (uint256 i = 0; i < _stakeIds.length; i++) {
            // gets current stake id in the loop
            uint256 _stakeId = _stakeIds[i];
            // call v1 core pool to get all required data associated with
            // the passed v1 stake id
            (uint256 tokenAmount, uint256 _weight, uint64 lockedFrom, uint64 lockedUntil, bool isYield) = ICorePoolV1(
                corePoolV1
            ).getDeposit(msg.sender, _stakeId);
            // checks if the obtained v1 stake (through getDeposit)
            // is indeed yield
            fnSelector.verifyState(isYield, i * 3);
            // expects the yield v1 stake to be unlocked
            fnSelector.verifyState(_now256() > lockedUntil, i * 4 + 1);
            // expects that the v1 stake hasn't been minted yet
            fnSelector.verifyState(!v1YieldMinted[msg.sender][_stakeId], i * 5 + 2);
            // verifies if the yield has been created before v2 launches
            fnSelector.verifyState(lockedFrom < _v1StakeMaxPeriod, i * 6 + 3);

            // marks v1 yield as minted
            v1YieldMinted[msg.sender][_stakeId] = true;
            // updates variables that will be used for minting yield and updating
            // user struct later
            amountToMint += tokenAmount;
            weightToRemove += _weight;
        }
        // subtracts value accumulated during the loop
        user.totalWeight -= (weightToRemove).toUint248();
        // subtracts weight and token value from global variables
        globalWeight -= weightToRemove;
        // gets token value by dividing by yield weight multiplier
        poolTokenReserve -= (weightToRemove) / Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;
        // expects the factory to mint ILV yield to the msg.sender user
        // after all checks and calculations have been successfully
        // executed
        _factory.mintYieldTo(msg.sender, amountToMint, false);

        // emits an event
        emit LogV1YieldMintedMultiple(msg.sender, amountToMint);
    }

    /**
     * @dev Verifies a proof from the yield weights merkle, and if it's valid,
     *      adds the v1 user yield weight to the v2 `user.totalWeight`.
     * @dev The yield weights merkle tree will be published after the initial contracts
     *      deployment, and then the merkle root is added through `setMerkleRoot` function.
     *
     * @param _proof bytes32 array with the proof generated off-chain
     * @param _index user index in the merkle tree
     * @param _yieldWeight user yield weight in v1 stored by the merkle tree
     * @param _pendingV1Rewards user pending rewards in v1 stored by the merkle tree
     * @param _useSILV whether the user wants rewards in sILV token or in a v2 ILV yield stake
     */
    function _migrateYieldWeights(
        bytes32[] calldata _proof,
        uint256 _index,
        uint256 _yieldWeight,
        uint256 _pendingV1Rewards,
        bool _useSILV
    ) internal virtual {
        // gets storage pointer to the user
        User storage user = users[msg.sender];
        // bytes4(keccak256("_migrateYieldWeights(bytes32[],uint256,uint256)")))
        bytes4 fnSelector = 0x660e5908;
        // requires that the user hasn't migrated the yield yet
        fnSelector.verifyAccess(!hasMigratedYield(_index));
        // compute leaf and verify merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(_index, msg.sender, _yieldWeight, _pendingV1Rewards));
        // verifies the merkle proof and requires the return value to be true
        fnSelector.verifyInput(MerkleProof.verify(_proof, merkleRoot, leaf), 0);
        // gets the value compounded into v2 as ILV yield to be added into v2 user.totalWeight
        uint256 pendingRewardsCompounded = _migratePendingRewards(_pendingV1Rewards, _useSILV);
        uint256 weightCompounded = pendingRewardsCompounded * Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;
        uint256 ilvYieldMigrated = _yieldWeight / Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;
        // add v1 yield weight to the v2 user
        user.totalWeight += (_yieldWeight + weightCompounded).toUint248();
        // adds v1 pending yield compounded + v1 total yield to global weight
        // and poolTokenReserve in the v2 contract.
        globalWeight += (weightCompounded + _yieldWeight);
        poolTokenReserve += (pendingRewardsCompounded + ilvYieldMigrated);
        // set user as claimed in bitmap
        _usersMigrated.set(_index);

        // emits an event
        emit LogMigrateYieldWeight(msg.sender, _yieldWeight);
    }

    /**
     * @dev Gets pending rewards in the v1 ilv pool and v1 lp pool stored in the merkle tree,
     *      and allows the v1 users of those pools to claim them as ILV compounded in the v2 pool or
     *      sILV minted to their wallet.
     * @dev Eligible users are filtered and stored in the merkle tree.
     *
     * @param _pendingV1Rewards user pending rewards in v1 stored by the merkle tree
     * @param _useSILV whether the user wants rewards in sILV token or in a v2 ILV yield stake
     *
     * @return pendingRewardsCompounded returns the value compounded into the v2 pool (if the user selects ILV)
     */
    function _migratePendingRewards(uint256 _pendingV1Rewards, bool _useSILV)
        internal
        virtual
        returns (uint256 pendingRewardsCompounded)
    {
        // gets pointer to user
        User storage user = users[msg.sender];

        // if the user (msg.sender) wants to mint pending rewards as sILV, simply mint
        if (_useSILV) {
            // calls the factory to mint sILV
            _factory.mintYieldTo(msg.sender, _pendingV1Rewards, _useSILV);
        } else {
            // otherwise we create a new v2 yield stake (ILV)
            Stake.Data memory stake = Stake.Data({
                value: (_pendingV1Rewards).toUint120(),
                lockedFrom: (_now256()).toUint64(),
                lockedUntil: (_now256() + Stake.MAX_STAKE_PERIOD).toUint64(),
                isYield: true
            });
            // adds new ILV yield stake to user array
            // notice that further values will be updated later in execution
            // (user.totalWeight, user.subYieldRewards, user.subVaultRewards, ...)
            user.stakes.push(stake);
            // updates function's return value
            pendingRewardsCompounded = _pendingV1Rewards;
        }

        // emits an event
        emit LogMigratePendingRewards(msg.sender, _pendingV1Rewards, _useSILV);
    }

    /**
     * @inheritdoc CorePool
     * @dev In the ILV Pool we verify that the user isn't coming from v1.
     * @dev If user has weight in v1, we can't allow them to call this
     *      function, otherwise it would throw an error in the new address when calling
     *      mintV1YieldMultiple if the user migrates.
     */

    function moveFundsFromWallet(address _to) public virtual override {
        // we're using function selector to simplify validation
        bytes4 fnSelector = this.moveFundsFromWallet.selector;
        // we query v1 ilv pool contract
        (, uint256 totalWeight, , ) = ICorePoolV1(corePoolV1).users(msg.sender);
        // we check that the v1 total weight is 0 i.e the user can't have any yield
        fnSelector.verifyState(totalWeight == 0, 0);
        // call parent moveFundsFromWalet which contains further checks and the actual
        // execution
        super.moveFundsFromWallet(_to);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}