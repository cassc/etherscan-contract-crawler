// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IMetarelics {
  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  function walletOfOwner(address _owner) external view returns (uint16[] memory);
}