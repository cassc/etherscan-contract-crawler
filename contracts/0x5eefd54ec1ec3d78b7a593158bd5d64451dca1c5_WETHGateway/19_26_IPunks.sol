// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IPunks {
  /**
   * @dev returns the balance of an account
   * @param account the given account
   **/
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev returns the address of a punk given its index
   * @param punkIndex the index
   **/
  function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

  /**
   * @dev buys a punk
   * @param punkIndex the index of the punk to buy
   **/
  function buyPunk(uint256 punkIndex) external;

  /**
   * @dev transfers a punk
   * @param to the recipient address
   * @param punkIndex the index of the punk to transfer
   **/
  function transferPunk(address to, uint256 punkIndex) external;
}