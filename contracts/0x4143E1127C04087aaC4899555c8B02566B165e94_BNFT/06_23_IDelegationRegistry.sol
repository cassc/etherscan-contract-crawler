// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
  /**
   * @notice Allow the delegate to act on your behalf for a specific token
   * @param delegate The hotwallet to act on your behalf
   * @param contract_ The address for the contract you're delegating
   * @param tokenId The token id for the token you're delegating
   * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
   */
  function delegateForToken(
    address delegate,
    address contract_,
    uint256 tokenId,
    bool value
  ) external;
}