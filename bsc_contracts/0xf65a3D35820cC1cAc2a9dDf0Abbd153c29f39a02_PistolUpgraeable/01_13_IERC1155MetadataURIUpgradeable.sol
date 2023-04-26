// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";

interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
  function uri(uint256 id) external view returns (string memory);
}