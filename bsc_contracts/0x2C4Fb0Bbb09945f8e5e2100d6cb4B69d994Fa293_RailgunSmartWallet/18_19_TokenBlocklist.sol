// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Token Blocklist
 * @author Railgun Contributors
 * @notice Blocklist of tokens that are incompatible with the protocol
 * @dev Tokens on this blocklist can't be shielded to railgun.
 * Tokens on this blocklist will still be transferrable
 * internally (as internal transactions have a shielded token ID) and
 * unshieldable (to prevent user funds from being locked)
 * THIS WILL ALWAYS BE A NON-EXHAUSTIVE LIST, DO NOT RELY ON IT BLOCKING ALL
 * INCOMPATIBLE TOKENS
 */
contract TokenBlocklist is OwnableUpgradeable {
  // Events for offchain building of blocklist index
  event AddToBlocklist(address indexed token);
  event RemoveFromBlocklist(address indexed token);

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading
  mapping(address => bool) public tokenBlocklist;

  /**
   * @notice Adds tokens to Blocklist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that are already in the Blocklist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to add to Blocklist
   */
  function addToBlocklist(address[] calldata _tokens) external onlyOwner {
    // Loop through token array
    for (uint256 i = 0; i < _tokens.length; i += 1) {
      // Don't do anything if the token is already blocklisted
      if (!tokenBlocklist[_tokens[i]]) {
        // Set token address in blocklist map to true
        tokenBlocklist[_tokens[i]] = true;

        // Emit event for building index of blocklisted tokens offchain
        emit AddToBlocklist(_tokens[i]);
      }
    }
  }

  /**
   * @notice Removes token from blocklist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that aren't in the blocklist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to remove from blocklist
   */
  function removeFromBlocklist(address[] calldata _tokens) external onlyOwner {
    // Loop through token array
    for (uint256 i = 0; i < _tokens.length; i += 1) {
      // Don't do anything if the token isn't blocklisted
      if (tokenBlocklist[_tokens[i]]) {
        // Set token address in blocklisted map to false (default value)
        delete tokenBlocklist[_tokens[i]];

        // Emit event for building index of blocklisted tokens off chain
        emit RemoveFromBlocklist(_tokens[i]);
      }
    }
  }

  uint256[49] private __gap;
}