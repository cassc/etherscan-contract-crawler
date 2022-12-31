/**
 *Submitted for verification at Etherscan.io on 2022-12-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IFiefdomsKingdom {
  function mintBatch(address to, uint256 amount) external;
  function mint(address to) external;
}

contract FiefdomsMinter {
  IFiefdomsKingdom public fiefdomsKingdom;
  constructor(address addr) {
    fiefdomsKingdom = IFiefdomsKingdom(addr);
  }

  /// @notice Mint a bunch of fiefdoms to an address
  /// @param to Recipient address
  /// @param amount Number of tokens to mint
  function mintALot(address to, uint256 amount) external {
    fiefdomsKingdom.mintBatch(to, amount);
  }

  /// @notice Mint a single fiefdom to an address
  /// @param to Recipient address
  function mintOne(address to) external {
    fiefdomsKingdom.mint(to);
  }
}