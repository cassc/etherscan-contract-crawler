// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title GovernanceErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors for the Arcade governance vault contracts. All errors
 * are prefixed by the contract that throws them (e.g., "NBV_" for NFTBoostVault).
 * Errors located in one place to make it possible to holistically look at all
 * governance failure cases.
 */

// ======================================== NFT BOOST VAULT ==========================================
/// @notice All errors prefixed with NBV_, to separate from other contracts in governance.

/**
 * @notice Ensure caller has not already registered.
 */
error NBV_HasRegistration();

/**
 * @notice Caller has not already registered.
 */
error NBV_NoRegistration();

/**
 * @notice Ensure delegatee is not already registered as the delegate in user's Registration.
 */
error NBV_AlreadyDelegated();

/**
 * @notice Contract balance has to be bigger than amount being withdrawn.
 */
error NBV_InsufficientBalance();

/**
 * @notice Withdrawable tokens less than withdraw request amount.
 *
 * @param withdrawable              The returned withdrawable amount from
 *                                  a user's registration.
 */
error NBV_InsufficientWithdrawableBalance(uint256 withdrawable);

/**
 * @notice Multiplier limit exceeded.
 *
 * @param limitType                 Whether the multiplier is too high or too low.
 */
error NBV_MultiplierLimit(string limitType);

/**
 * @notice No multiplier has been set for the specified ERC1155 token.
 */
error NBV_NoMultiplierSet();

/**
 * @notice Multiplier has already been set for the specified ERC1155 token.
 */
error NBV_MultiplierSet(uint128 multiplier, uint128 expiration);

/**
 * @notice The provided token address and token id are invalid.
 *
 * @param tokenAddress              The token address provided.
 * @param tokenId                   The token id provided.
 */
error NBV_InvalidNft(address tokenAddress, uint256 tokenId);

/**
 * @notice User is calling withdraw() with zero amount.
 */
error NBV_ZeroAmount();

/**
 * @notice Zero address passed in where not allowed.
 *
 * @param addressType                The name of the parameter for which
 *                                   a zero address was provided.
 */
error NBV_ZeroAddress(string addressType);

/**
 * @notice Provided addresses array holds more than 50 addresses.
 */
error NBV_ArrayTooManyElements();

/** @notice NFT Boost Voting Vault has already been unlocked.
 */
error NBV_AlreadyUnlocked();

/**
 * @notice ERC20 withdrawals from NFT Boost Voting Vault are frozen.
 */
error NBV_Locked();

/**
 * @notice Airdrop contract is not the caller.
 */
error NBV_NotAirdrop();

/**
 * @notice If a user already has a registration, they cannot change their
 *         delegatee when claiming subsequent airdrops.
 */
error NBV_WrongDelegatee(address newDelegate, address currentDelegate);

/**
 * @notice The multiplier expiration provided has already passed.
 */
error NBV_InvalidExpiration();

// ==================================== VESTING VOTING VAULT ======================================
/// @notice All errors prefixed with AVV_, to separate from other contracts in governance.

/**
 * @notice Block number parameters used to create a grant are invalid. Check that the start time is
 *         before the cliff, and the cliff is before the expiration.
 */
error AVV_InvalidSchedule();

/**
 * @notice The cliff block number cannot be less than the current block.
 */
error AVV_InvalidCliff();

/**
 * @notice Cliff amount should be less than the grant amount.
 */
error AVV_InvalidCliffAmount();

/**
 * @notice Insufficient balance to carry out the transaction.
 *
 * @param amountAvailable           The amount available in the vault.
 */
error AVV_InsufficientBalance(uint256 amountAvailable);

/**
 * @notice Grant has already been created for specified user.
 */
error AVV_HasGrant();

/**
 * @notice Grant has not been created for the specified user.
 */
error AVV_NoGrantSet();

/**
 * @notice Tokens cannot be claimed before the cliff.
 *
 * @param cliffBlock                The block number when grant claims begin.
 */
error AVV_CliffNotReached(uint256 cliffBlock);

/**
 * @notice Tokens cannot be re-delegated to the same address.
 */
error AVV_AlreadyDelegated();

/**
 * @notice Cannot withdraw zero tokens.
 */
error AVV_InvalidAmount();

/**
 * @notice Zero address passed in where not allowed.
 *
 * @param addressType                The name of the parameter for which
 *                                   a zero address was provided.
 */
error AVV_ZeroAddress(string addressType);

// =================================== IMMUTABLE VESTING VAULT ===================================
/// @notice All errors prefixed with IVV_, to separate from other contracts in governance.

/**
 * @notice Grants cannot be revoked from the immutable vesting vault.
 */
error IVV_ImmutableGrants();

// ====================================== BASE VOTING VAULT ======================================
/// @notice All errors prefixed with BVV_, to separate from other contracts in governance.

/**
 * @notice Caller is not the manager.
 */
error BVV_NotManager();

/**
 * @notice Caller is not the timelock.
 */
error BVV_NotTimelock();

/**
 * @notice Zero address passed in where not allowed.
 *
 * @param addressType                The name of the parameter for which a zero
 *                                   address was provided.
 */
error BVV_ZeroAddress(string addressType);

/**
 * @notice The provided stale block number is too high.
 *
 * @param staleBlock                The block number in the past, provided at deployment
 *                                  before which a user's history is pruned.
 */
error BVV_UpperLimitBlock(uint256 staleBlock);