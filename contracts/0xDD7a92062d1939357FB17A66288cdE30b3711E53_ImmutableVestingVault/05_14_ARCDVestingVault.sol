// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/BoundedHistory.sol";
import "./external/council/libraries/Storage.sol";

import "./libraries/ARCDVestingVaultStorage.sol";

import "./interfaces/IARCDVestingVault.sol";
import "./BaseVotingVault.sol";

import {
    AVV_InvalidSchedule,
    AVV_InvalidCliff,
    AVV_InvalidCliffAmount,
    AVV_InsufficientBalance,
    AVV_HasGrant,
    AVV_NoGrantSet,
    AVV_CliffNotReached,
    AVV_AlreadyDelegated,
    AVV_InvalidAmount,
    AVV_ZeroAddress
} from "./errors/Governance.sol";

/**
 * @title ARCDVestingVault
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract is a vesting vault for the Arcade token. It allows for the creation of grants
 * which can be vested over time. The vault has a manager who can add and remove grants.
 * The vault also has a timelock which can change the manager.
 *
 * When a grant is created by a manager, the manager specifies the delegatee. This is the address
 * that will receive the voting power of the grant. The delegatee can be updated by the grant
 * recipient at any time. When a grant is created, there are three time parameters:
 *      created - The block number the grant starts at. If not specified, the current block is used.
 *      cliff - The block number the cliff ends at. No tokens are unlocked until this block is reached.
 *              The cliffAmount parameter is the amount of tokens that will be unlocked at the cliff.
 *      expiration - The block number the grant ends at. All tokens are unlocked at this block.
 *
 * @dev There is no emergency withdrawal, any funds not sent via deposit() are unrecoverable
 *      by this version of the VestingVault. When grants are added the contracts will not transfer
 *      in tokens on each add but rather check for solvency via state variables.
 */
contract ARCDVestingVault is IARCDVestingVault, BaseVotingVault {
    using BoundedHistory for BoundedHistory.HistoricalBalances;
    using ARCDVestingVaultStorage for ARCDVestingVaultStorage.Grant;
    using Storage for Storage.Address;
    using Storage for Storage.Uint256;
    using SafeERC20 for IERC20;

    // ========================================= CONSTRUCTOR ============================================

    /**
     * @notice Deploys a new vesting vault, setting relevant immutable variables
     *         and granting management power to a defined address.
     *
     * @param _token              The ERC20 token to grant.
     * @param _stale              Stale block used for voting power calculations
     * @param manager_            The address of the manager.
     * @param timelock_           The address of the timelock.
     */
    constructor(IERC20 _token, uint256 _stale, address manager_, address timelock_) BaseVotingVault(_token, _stale) {
        if (manager_ == address(0)) revert AVV_ZeroAddress("manager");
        if (timelock_ == address(0)) revert AVV_ZeroAddress("timelock");

        Storage.set(Storage.addressPtr("manager"), manager_);
        Storage.set(Storage.addressPtr("timelock"), timelock_);
        Storage.set(Storage.uint256Ptr("entered"), 1);
    }

    // ==================================== MANAGER FUNCTIONALITY =======================================

    /**
     * @notice Adds a new grant. The manager sets who the voting power will be delegated to initially.
     *         This potentially avoids the need for a delegation transaction by the grant recipient.
     *
     * @param who                        The Grant recipient.
     * @param amount                     The total grant value.
     * @param cliffAmount                The amount of tokens that will be unlocked at the cliff.
     * @param expiration                 Block number when the grant ends - all tokens are unlocked and withdrawable.
     * @param cliff                      Block number when token withdrawals can start.
     * @param delegatee                  The address to delegate the voting power to
     */
    function addGrantAndDelegate(
        address who,
        uint128 amount,
        uint128 cliffAmount,
        uint64 expiration,
        uint64 cliff,
        address delegatee
    ) external onlyManager {
        // input validation
        if (who == address(0)) revert AVV_ZeroAddress("who");
        if (amount == 0) revert AVV_InvalidAmount();

        // cliff must be in the future
        if (cliff < block.number) revert AVV_InvalidCliff();

        // cliff must be less than the expiration
        if (cliff >= expiration) revert AVV_InvalidSchedule();

        // check cliff unlock amount is less than the total grant amount
        if (cliffAmount >= amount) revert AVV_InvalidCliffAmount();

        Storage.Uint256 storage unassigned = _unassigned();
        if (unassigned.data < amount) revert AVV_InsufficientBalance(unassigned.data);

        // load the grant
        ARCDVestingVaultStorage.Grant storage grant = _grants()[who];

        // if this address already has a grant, a different address must be provided
        // topping up or editing active grants is not supported.
        if (grant.allocation != 0) revert AVV_HasGrant();

        // load the delegate. Defaults to the grant owner
        delegatee = delegatee == address(0) ? who : delegatee;

        // calculate the voting power. Assumes all voting power is initially locked.
        uint128 newVotingPower = amount;

        // set the new grant
        grant.allocation = amount;
        grant.cliffAmount = cliffAmount;
        grant.withdrawn = 0;
        grant.expiration = expiration;
        grant.cliff = cliff;
        grant.latestVotingPower = newVotingPower;
        grant.delegatee = delegatee;

        // update the amount of unassigned tokens
        unassigned.data -= amount;

        // update the delegatee's voting power
        BoundedHistory.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(grant.delegatee);
        votingPower.push(grant.delegatee, delegateeVotes + newVotingPower, MAX_HISTORY_LENGTH);

        emit VoteChange(grant.delegatee, who, int256(uint256(newVotingPower)));
    }

    /**
     * @notice Removes a grant. Any available vested tokens will be sent to the grant recipient.
     *         Any remaining unvested tokens will be sent to the vesting manager.
     *
     * @param who             The grant owner.
     */
    function revokeGrant(address who) external virtual onlyManager {
        // load the grant
        ARCDVestingVaultStorage.Grant storage grant = _grants()[who];

        // if the grant has already been removed or no grant available, revert
        if (grant.allocation == 0) revert AVV_NoGrantSet();

        // get the amount of withdrawable tokens and transfer to the grant recipient
        uint256 withdrawable = _getWithdrawableAmount(grant);
        grant.withdrawn += uint128(withdrawable);
        token.safeTransfer(who, withdrawable);

        // transfer any unvested tokens to the manager
        uint256 remaining = grant.allocation - grant.withdrawn;
        if (remaining > 0) {
            grant.withdrawn += uint128(remaining);
            token.safeTransfer(msg.sender, remaining);
        }

        // update the delegatee's voting power
        _syncVotingPower(who, grant);

        // delete the grant
        grant.allocation = 0;
        grant.cliffAmount = 0;
        grant.withdrawn = 0;
        grant.expiration = 0;
        grant.cliff = 0;
        grant.latestVotingPower = 0;
        grant.delegatee = address(0);
    }

    /**
     * @notice Manager-only token deposit function.  Deposited tokens are added to `_unassigned`
     *         and can be used to create grants.
     *
     * @dev This is the only way to deposit tokens into the contract. Any tokens sent via other
     *      means are not recoverable by this contract.
     *
     * @param amount           The amount of tokens to deposit.
     */
    function deposit(uint256 amount) external onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        // update unassigned value
        unassigned.data += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Manager-only token withdrawal function. The manager can only withdraw tokens that
     *         are not being used by a grant.
     *
     * @param amount           The amount to withdraw.
     * @param recipient        The address to withdraw to.
     */
    function withdraw(uint256 amount, address recipient) external override onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        if (unassigned.data < amount) revert AVV_InsufficientBalance(unassigned.data);
        // update unassigned value
        unassigned.data -= amount;

        token.safeTransfer(recipient, amount);
    }

    // ========================================= USER OPERATIONS ========================================

    /**
     * @notice Grant owners use to claim any withdrawable value from a grant. Voting power
     *         is recalculated factoring in the amount withdrawn.
     *
     * @param amount                 The amount to withdraw.
     */
    function claim(uint256 amount) external override nonReentrant {
        if (amount == 0) revert AVV_InvalidAmount();

        // load the grant
        ARCDVestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        if (grant.allocation == 0) revert AVV_NoGrantSet();
        if (grant.cliff > block.number) revert AVV_CliffNotReached(grant.cliff);

        // get the withdrawable amount
        uint256 withdrawable = _getWithdrawableAmount(grant);
        if (amount > withdrawable) revert AVV_InsufficientBalance(withdrawable);

        // update the grant's withdrawn amount
        if (amount == withdrawable) {
            grant.withdrawn += uint128(withdrawable);
        } else {
            grant.withdrawn += uint128(amount);
            withdrawable = amount;
        }

        // update the user's voting power
        _syncVotingPower(msg.sender, grant);

        // transfer the available amount
        token.safeTransfer(msg.sender, withdrawable);
    }

    /**
     * @notice Updates the caller's voting power delegatee.
     *
     * @param to              The address to delegate to.
     */
    function delegate(address to) external {
        ARCDVestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        if (to == grant.delegatee) revert AVV_AlreadyDelegated();

        // check if the grant has been set
        if (grant.allocation == 0) revert AVV_NoGrantSet();

        BoundedHistory.HistoricalBalances memory votingPower = _votingPower();
        uint256 oldDelegateeVotes = votingPower.loadTop(grant.delegatee);

        // Remove old delegatee's voting power and emit event
        votingPower.push(grant.delegatee, oldDelegateeVotes - grant.latestVotingPower, MAX_HISTORY_LENGTH);
        emit VoteChange(grant.delegatee, msg.sender, -1 * int256(grant.latestVotingPower));

        // Note - It is important that this is loaded here and not before the previous state change because if
        // to == grant.delegatee and re-delegation was allowed we could be working with out of date state.
        uint256 newDelegateeVotes = votingPower.loadTop(to);

        // add voting power to the target delegatee and emit event
        votingPower.push(to, newDelegateeVotes + grant.latestVotingPower, MAX_HISTORY_LENGTH);

        // update grant delgatee info
        grant.delegatee = to;

        emit VoteChange(msg.sender, to, int256(uint256(grant.latestVotingPower)));
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Returns the claimable amount for a given grant.
     *
     * @param who                    Address to query.
     *
     * @return Token amount that can be claimed.
     */
    function claimable(address who) external view returns (uint256) {
        return _getWithdrawableAmount(_grants()[who]);
    }

    /**
     * @notice Getter function for the grants mapping.
     *
     * @param who            The owner of the grant to query
     *
     * @return               The user's grant object.
     */
    function getGrant(address who) external view returns (ARCDVestingVaultStorage.Grant memory) {
        return _grants()[who];
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice Calculates and returns how many tokens a grant recipient can withdraw.
     *
     * @param grant                    The memory location of the loaded grant.
     *
     * @return amount                  Number of tokens the grant owner can withdraw.
     */
    function _getWithdrawableAmount(ARCDVestingVaultStorage.Grant memory grant) internal view returns (uint256) {
        // if before cliff, no tokens have unlocked
        if (block.number < grant.cliff) {
            return 0;
        }
        // if after expiration, return the full allocation minus what has already been withdrawn
        if (block.number >= grant.expiration) {
            return grant.allocation - grant.withdrawn;
        }
        // if after cliff, return vested amount minus what has already been withdrawn
        uint256 postCliffAmount = grant.allocation - grant.cliffAmount;
        uint256 blocksElapsedSinceCliff = block.number - grant.cliff;
        uint256 totalBlocksPostCliff = grant.expiration - grant.cliff;
        uint256 unlocked = grant.cliffAmount + (postCliffAmount * blocksElapsedSinceCliff) / totalBlocksPostCliff;

        return unlocked - grant.withdrawn;
    }

    /**
     * @notice Helper to update a delegatee's voting power.
     *
     * @param who                       The address who's voting power we need to sync.
     * @param grant                     The storage pointer to the grant of that user.
     */
    function _syncVotingPower(address who, ARCDVestingVaultStorage.Grant storage grant) internal {
        BoundedHistory.HistoricalBalances memory votingPower = _votingPower();

        uint256 delegateeVotes = votingPower.loadTop(grant.delegatee);

        uint256 newVotingPower = grant.allocation - grant.withdrawn;

        // get the change in voting power. voting power can only go down
        // since the sync is only called when tokens are claimed or grant revoked
        int256 change = int256(newVotingPower) - int256(grant.latestVotingPower);
        // we multiply by -1 to avoid underflow when casting
        if (delegateeVotes > uint256(change * -1)) {
            votingPower.push(grant.delegatee, delegateeVotes - uint256(change * -1), MAX_HISTORY_LENGTH);
        } else {
            votingPower.push(grant.delegatee, 0, MAX_HISTORY_LENGTH);
        }

        grant.latestVotingPower = newVotingPower;

        emit VoteChange(grant.delegatee, who, change);
    }

    /**
     * @notice A single function endpoint for loading grant storage. Returns a
     *         storage mapping which can be used to look up grant data.
     *
     * @dev Only one Grant is allowed per address. If a grant is revoked, the
     *      grant is deleted.
     *
     * @return grants                   Pointer to the grant storage mapping.
     */
    function _grants() internal pure returns (mapping(address => ARCDVestingVaultStorage.Grant) storage) {
        // This call returns a storage mapping with a unique non overwrite-able storage location
        // which can be persisted through upgrades, even if they change storage layout
        return (ARCDVestingVaultStorage.mappingAddressToGrantPtr("grants"));
    }

    /**
     * @notice A function to access the storage of the unassigned token value.
     *         The unassigned tokens are not part of any grant and can be used for a future
     *         grant or withdrawn by the manager.
     *
     * @return unassigned               Pointer to the unassigned token value.
     */
    function _unassigned() internal pure returns (Storage.Uint256 storage) {
        return Storage.uint256Ptr("unassigned");
    }
}