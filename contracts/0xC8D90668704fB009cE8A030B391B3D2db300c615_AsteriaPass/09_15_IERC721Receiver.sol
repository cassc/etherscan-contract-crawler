// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
* @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
*/
interface IERC721Receiver {
  /**
  * @notice Handle the receipt of an NFT
  * @dev The ERC721 smart contract calls this function on the recipient
  *   after a `transfer`. This function MAY throw to revert and reject the
  *   transfer. Return of other than the magic value MUST result in the
  *   transaction being reverted.
  * Note: the contract address is always the message sender.
  */
  function onERC721Received(
    address operator_,
    address from_,
    uint256 tokenId_,
    bytes calldata data_
  ) external returns(bytes4);
}