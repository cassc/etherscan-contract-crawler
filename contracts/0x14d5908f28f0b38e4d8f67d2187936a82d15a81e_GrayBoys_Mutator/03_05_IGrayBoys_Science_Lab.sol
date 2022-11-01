// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IGrayBoys_Science_Lab is IERC1155 {
  function burnMaterialForOwnerAddress(uint256 _typeId, uint256 _quantity, address _materialOwnerAddress) external;
  function mintMaterialToAddress(uint256 _typeId, uint256 _quantity, address _toAddress) external;
  function bulkSafeTransfer(uint256 _typeId, uint256 _quantityPerRecipient, address[] calldata recipients) external;
}