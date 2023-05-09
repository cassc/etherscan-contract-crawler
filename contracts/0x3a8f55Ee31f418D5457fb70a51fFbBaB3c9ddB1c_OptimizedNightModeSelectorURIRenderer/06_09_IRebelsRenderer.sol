// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IRebelsRenderer is IERC165 {
  function tokenURI(uint256 id) external view returns (string memory);
  function beforeTokenTransfer(address from, address to, uint256 id) external;
}