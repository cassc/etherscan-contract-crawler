// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ICorePoolV1 } from "../interfaces/ICorePoolV1.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";
import { Stake } from "../libraries/Stake.sol";
import { CorePool } from "./CorePool.sol";

/**
 * @title V2Migrator
 *
 * @dev V2Migrator inherits all CorePool base contract functionaltiy, and adds
 *      v1 to v2 migration related functions. This is a core smart contract of
 *      Sushi LP and ILV pools, and manages users locked and yield weights coming
 *      from v1.
 * @dev Parameters need to be reviewed carefully before deployment for the migration process.
 * @dev Users will migrate their locked stakes, which are stored in the contract,
 *      and v1 total yield weights by data stored in a merkle tree using merkle proofs.
 */
abstract contract V2Migrator is Initializable, CorePool {
    using ErrorHandler for bytes4;
    using Stake for uint256;

    /// @dev Maps v1 addresses that are black listed for v2 migration.
    mapping(address => bool) public isBlacklisted;

    /// @dev Stores maximum timestamp of a v1 stake (yield or deposit) accepted in v2.
    uint256 internal _v1StakeMaxPeriod;

    /**
     * @dev logs `_migrateLockedStakes()`
     *
     * @param from user address
     * @param totalV1WeightAdded total amount of weight coming from locked stakes in v1
     *
     */
    event LogMigrateLockedStakes(address indexed from, uint256 totalV1WeightAdded);

    /**
     * @dev V2Migrator initializer function.
     *
     * @param v1StakeMaxPeriod_ max timestamp that we accept _lockedFrom values
     *                         in v1 stakes
     */
    function __V2Migrator_init(
        address ilv_,
        address silv_,
        address _poolToken,
        address _corePoolV1,
        address factory_,
        uint64 _initTime,
        uint32 _weight,
        uint256 v1StakeMaxPeriod_
    ) internal initializer {
        // call internal core pool intializar
        __CorePool_init(ilv_, silv_, _poolToken, _corePoolV1, factory_, _initTime, _weight);
        // sets max period for upgrading to V2 contracts i.e migrating
        _v1StakeMaxPeriod = v1StakeMaxPeriod_;
    }

    /**
     * @notice Blacklists a list of v1 user addresses by setting the
     *         _isBlacklisted flag to true.
     *
     * @dev The intention is to prevent addresses that exploited v1 to be able to move
     *      stake ids to the v2 contracts and to be able to mint any yield from a v1
     *      stake id with the isYield flag set to true.
     *
     * @param _users v1 users address array
     */
    function blacklistUsers(address[] calldata _users) external virtual {
        // only the factory controller can blacklist users
        _requireIsFactoryController();
        // we're using selector to simplify validation
        bytes4 fnSelector = this.blacklistUsers.selector;
        // gets each user in the array to be blacklisted
        for (uint256 i = 0; i < _users.length; i++) {
            // makes sure user passed isn't the address 0
            fnSelector.verifyInput(_users[i] != address(0), 0);
            // updates mapping
            isBlacklisted[_users[i]] = true;
        }
    }

    /**
     * @dev External migrateLockedStakes call, used in the Sushi LP pool contract.
     * @dev The function is used by users that want to migrate locked stakes in v1,
     *      but have no yield in the pool. This happens in two scenarios:
     *
     *      1 - The user pool is the Sushi LP pool, which only has stakes;
     *      2 - The user joined ILV pool recently, doesn't have much yield and
     *          doesn't want to migrate their yield weight in the pool;
     * @notice Most of the times this function will be used in the inherited Sushi
     *         LP pool contract (called by the v1 user coming from sushi pool),
     *         but it's possible that a v1 user coming from the ILV pool decides
     *         to use this function instead of `executeMigration()` defined in
     *         the ILV pool contract.
     *
     * @param _stakeIds array of v1 stake ids
     */
    function migrateLockedStakes(uint256[] calldata _stakeIds) external virtual {
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
    }

    /**
     * @dev Reads v1 core pool locked stakes data (by looping through the `_stakeIds` array),
     *      checks if it's a valid v1 stake to migrate and save the id to v2 user struct.
     *
     * @dev Only `msg.sender` can migrate v1 stakes to v2.
     *
     * @param _stakeIds array of v1 stake ids
     */
    function _migrateLockedStakes(uint256[] calldata _stakeIds) internal virtual {
        User storage user = users[msg.sender];
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_migrateLockedStakes(uint256[])"))`
        bytes4 fnSelector = 0x80812525;
        // initializes variable which will tell how much
        // weight in v1 the user is bringing to v2
        uint256 totalV1WeightAdded;

        // loops over each v1 stake id passed to do the necessary validity checks
        // and store the values required in v2 to keep track of v1 weight in order
        // to include it in v2 rewards (yield and revenue distribution) calculations
        for (uint256 i = 0; i < _stakeIds.length; i++) {
            // reads the v1 stake by calling the v1 core pool getDeposit and separates
            // all required data in the struct to be used
            (, uint256 _weight, uint64 lockedFrom, , bool isYield) = ICorePoolV1(corePoolV1).getDeposit(
                msg.sender,
                _stakeIds[i]
            );
            // checks if the v1 stake is in the valid period for migration
            fnSelector.verifyState(lockedFrom <= _v1StakeMaxPeriod, i * 3);
            // checks if the v1 stake has been locked originally and isn't a yield
            // stake, which are the requirements for moving to v2 through this function
            fnSelector.verifyState(lockedFrom > 0 && !isYield, i * 3 + 1);
            // checks if the user has already brought those v1 stakes to v2
            fnSelector.verifyState(v1StakesWeights[msg.sender][_stakeIds[i]] == 0, i * 3 + 2);

            // adds v1 weight to the dynamic mapping which will be used in calculations
            v1StakesWeights[msg.sender][_stakeIds[i]] = _weight;
            // updates the variable keeping track of the total weight migrated
            totalV1WeightAdded += _weight;
            // update value keeping track of v1 stakes ids mapping length
            user.v1IdsLength++;
            // adds stake id to mapping keeping track of each v1 stake id
            user.v1StakesIds[user.v1IdsLength - 1] = _stakeIds[i];
        }

        // emits an event
        emit LogMigrateLockedStakes(msg.sender, totalV1WeightAdded);
    }

    /**
     * @dev Utility used by functions that can't allow blacklisted users to call.
     * @dev Blocks user addresses stored in the _isBlacklisted mapping to call actions like
     *      minting v1 yield stake ids and migrating locked stakes.
     */
    function _requireNotBlacklisted(address _user) internal view virtual {
        // we're using selector to simplify input and access validation
        bytes4 fnSelector = this.migrateLockedStakes.selector;
        // makes sure that msg.sender isn't a blacklisted address
        fnSelector.verifyAccess(!isBlacklisted[_user]);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}