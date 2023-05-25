// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

/**
  @title A minimalistic, gas-efficient ERC-721 implementation forked from the
    `Super721` ERC-721 implementation used by SuperFarm.
  @author Tim Clancy
  @author 0xthrpw
  @author Qazawat Zirak
  @author Rostislav Khlebnikov

  Compared to the original `Super721` implementation that this contract forked
  from, this is a very pared-down contract that includes simple delegated
  minting and transfer locks.

  This contract includes the gas efficiency techniques graciously shared with
  the world in the specific ERC-721 implementation by Chiru Labs that is being
  called "ERC-721A" (https://github.com/chiru-labs/ERC721A). We have validated
  this contract against their test cases.

  February 8th, 2022.
*/
interface ITiny721 {

  /**
    Return whether or not the transfer of a particular token ID `_id` is locked.

    @param _id The ID of the token to check the lock status of.

    @return Whether or not the particular token ID `_id` has transfers locked.
  */
  function transferLocks (
    uint256 _id
  ) external returns (bool);

  /**
    Provided with an address parameter, this function returns the number of all
    tokens in this collection that are owned by the specified address.

    @param _owner The address of the account for which we are checking balances
  */
  function balanceOf (
    address _owner
  ) external returns ( uint256 );

  /**
    Return the address that holds a particular token ID.

    @param _id The token ID to check for the holding address of.

    @return The address that holds the token with ID of `_id`.
  */
  function ownerOf (
    uint256 _id
  ) external returns (address);

  /**
    This function allows permissioned minters of this contract to mint one or
    more tokens dictated by the `_amount` parameter. Any minted tokens are sent
    to the `_recipient` address.

    Note that tokens are always minted sequentially starting at one. That is,
    the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
    Also note that per our use cases the intended recipient of these minted
    items will always be externally-owned accounts and not other contracts. As a
    result there is no safety check on whether or not the mint destination can
    actually correctly handle an ERC-721 token.

    @param _recipient The recipient of the tokens being minted.
    @param _amount The amount of tokens to mint.
  */
  function mint_Qgo (
    address _recipient,
    uint256 _amount
  ) external;

  /**
    This function allows an administrative caller to lock the transfer of
    particular token IDs. This is designed for a non-escrow staking contract
    that comes later to lock a user's NFT while still letting them keep it in
    their wallet.

    @param _id The ID of the token to lock.
    @param _locked The status of the lock; true to lock, false to unlock.
  */
  function lockTransfer (
    uint256 _id,
    bool _locked
  ) external;
}