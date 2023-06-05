// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC1155Receiver {
  /**
  * @dev Handles the receipt of a single ERC1155 token type.
  *   This function is called at the end of a {safeTransferFrom} after the balance has been updated.
  *   To accept the transfer, this must return
  *   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
  *   (i.e. 0xf23a6e61, or its own function selector).
  */
  function onERC1155Received(
    address operator_,
    address from_,
    uint256 id_,
    uint256 value_,
    bytes calldata data_
  ) external returns (bytes4);
  /**
  * @dev Handles the receipt of a multiple ERC1155 token types.
  *   This function is called at the end of a {safeBatchTransferFrom} after the balances have been updated.
  *   To accept the transfer(s), this must return
  *   `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
  *   (i.e. 0xbc197c81, or its own function selector).
  */
  function onERC1155BatchReceived(
    address operator_,
    address from_,
    uint256[] calldata ids_,
    uint256[] calldata values_,
    bytes calldata data_
  ) external returns (bytes4);
}