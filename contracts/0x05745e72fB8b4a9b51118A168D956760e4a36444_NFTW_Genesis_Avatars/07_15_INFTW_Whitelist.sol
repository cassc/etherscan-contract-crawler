// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INFTW_Whitelist is IERC1155 {
  function burnTypeBulk(uint256 _typeId, address[] calldata owners) external;
  function burnTypeForOwnerAddress(uint256 _typeId, uint256 _quantity, address _typeOwnerAddress) external returns (bool);
  function mintTypeToAddress(uint256 _typeId, uint256 _quantity, address _toAddress) external returns (bool);
  function bulkSafeTransfer(uint256 _typeId, uint256 _quantityPerRecipient, address[] calldata recipients) external;
}