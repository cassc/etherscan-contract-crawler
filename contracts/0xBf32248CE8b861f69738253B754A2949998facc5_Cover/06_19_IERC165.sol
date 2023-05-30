// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC165 {
  /**
  * @notice Returns if a contract implements an interface.
  * @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
  */
  function supportsInterface(bytes4 interfaceId_) external view returns (bool);
}