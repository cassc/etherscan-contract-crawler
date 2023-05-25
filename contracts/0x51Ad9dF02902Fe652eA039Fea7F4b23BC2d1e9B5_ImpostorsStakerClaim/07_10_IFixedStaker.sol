// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

/**
  @title A simple staking contract for transfer-locking `Tiny721` items in
    exchange for tokens.
  @author Tim Clancy
  @author Rostislav Khlebnikov
  @author 0xthrpw

  This staking contract disburses tokens from its internal reservoir to those
  who stake `Tiny721` items, at a fixed rate of token per item independent of
  the number of items staked. It supports defining multiple time-locked pools
  with different rates.

  April 28th, 2022.
*/
interface IFixedStaker {

  /**
    Retrieve details about a particular staker `_staker`'s `Position` in a
    particular pool `_id`.

    @param _id The ID of the pool to retrieve a position for.
    @param _staker The address of the staker to retrieve a position for.

    @return A deconstructed `Position` as a tuple of the array of staked item
      IDs and the amount of token paid out in total for that user's position.
  */
  function getPosition (
    uint256 _id,
    address _staker
  ) external view returns (uint256[] memory, uint256);

  /**
    View to retrieve current pending rewards for a user

    @param _poolIds the pools we are inquiring about
    @param _user the address of the account being queried
  */
  function pendingClaims (
    uint256[] memory _poolIds,
    address _user
  ) external view returns (uint256 totalClaimAmount);

  /**
    Allow the contract owner to add a new staking `Pool` to the Staker or
    overwrite the configuration of an existing one.

    @param _id The ID of the `Pool` to add or update.
    @param _item The address of the item contract that is staked in this pool.
    @param _lockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is locked during the `lockDuration`.
    @param _unlockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is unlocked and available for
      withdrawal.
    @param _lockDuration The amount of time in seconds where this pool requires
      that the asset remain time-locked and unavailable to withdraw. Once the
      item has been staked for `lockDuration` seconds, the item may be
      withdrawn from the pool and the number of tokens earned changes to the
      `unlockedTokensPerSecond` rate.
    @param _deadline The timestamp stakes must be created by, any stakes to
      pool that are attempted after this timestamp will revert.
  */
  function setPool (
    uint256 _id,
    address _item,
    uint256 _lockedTokensPerSecond,
    uint256 _unlockedTokensPerSecond,
    uint256 _lockDuration,
    uint256 _deadline
  ) external;

  /**
    Claim all of the caller's pending tokens from the specified pools.

    @param _poolIds The IDs of the pools to claim pending token rewards from.
  */
  function claim (
    uint256[] memory _poolIds
  ) external;

  /**
    Lock some particular token IDs from some particular contract addresses into
    some particular `Pool` of this Staker.

    @param _poolId The ID of the `Pool` to stake items in.
    @param _tokenIds An array of token IDs corresponding to specific tokens in
      the item contract from `Pool` with the ID of `_poolId`.
  */
  function stake (
    uint256 _poolId,
    uint256[] calldata _tokenIds
  ) external;

  /**
    Unlock some particular token IDs from some particular contract addresses
    from some particular `Pool` of this Staker.

    @param _poolId The ID of the `Pool` to unstake items from.
    @param _tokenIds An array of token IDs corresponding to specific tokens in
      the item contract from `Pool` with the ID of `_poolId` that are to be
      unstaked.
  */
  function withdraw (
    uint256 _poolId,
    uint256[] calldata _tokenIds
  ) external;

  /**
    Allow the owner to forcibly unlock some particular token IDs from some
    particular contract addresses from some particular `Pool` of this Staker.
    The eviction mechanic allows the owner to intervene in cases where item
    locks induce issues in the broader third-party ecosystem, namely in regards
    to unfulfillable marketplace listings. An address whose items are being
    forcibly evicted may optionally be banned from staking and may optionally
    have its rewards not delivered.

    @param _evictee The address being evicted from the specified pool.
    @param _poolId The ID of the `Pool` to evict items from.
    @param _tokenIds An array of token IDs corresponding to specific tokens in
      the item contract from `Pool` with the ID of `_poolId` that are to be
      evicted.
    @param _ban Whether or not the `_evictee` should be banned from future
      staking.
    @param _skipClaim Whether or not the `_evictee`'s pending claims should be
      skipped.
  */
  function evict (
    address _evictee,
    uint256 _poolId,
    uint256[] calldata _tokenIds,
    bool _ban,
    bool _skipClaim
  ) external;

  /**
    Set whether or not an address is banned from staking.

    @param _caller The caller to ban or unban.
    @param _banned Whether or not `_caller` is banned.
  */
  function setBan (
    address _caller,
    bool _banned
  ) external;

  /**
    Allow the owner to sweep either Ether or a particular ERC-20 token from the
    contract and send it to another address. This allows the owner of the shop
    to withdraw their funds after the sale is completed.

    @param _token The token to sweep the balance from; if a zero address is sent
      then the contract's balance of Ether will be swept.
    @param _amount The amount of token to sweep.
    @param _destination The address to send the swept tokens to.
  */
  function sweep (
    address _token,
    address _destination,
    uint256 _amount
  ) external;
}