// SPDX-License-Identifier: None
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ITether is IERC165 {
  function tether(uint256 tokenId) external;
}