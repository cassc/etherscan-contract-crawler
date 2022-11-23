// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver {
  /**
   * @notice validate receipt of ERC1155 transfer
   * @param operator executor of transfer
   * @param from sender of tokens
   * @param id token ID received
   * @param value quantity of tokens received
   * @param data data payload
   * @return function's own selector if transfer is accepted
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);
}
