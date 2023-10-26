// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

interface ENS {
  /**
   * @dev Returns the address that owns the specified node.
   * @param node The specified node.
   * @return address of the owner.
   */
  function owner(bytes32 node) external view returns (address);
}