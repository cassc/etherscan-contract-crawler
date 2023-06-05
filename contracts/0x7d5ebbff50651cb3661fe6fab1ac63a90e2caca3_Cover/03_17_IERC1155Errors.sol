// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC1155Errors {
  /**
  * @dev Thrown when `operator` has not been approved to manage `tokenId` on behalf of `tokenOwner`.
  * 
  * @param from address owning the token
  * @param operator address trying to manage the token
  */
  error IERC1155_CALLER_NOT_APPROVED(address from, address operator);
  /**
  * @dev Thrown when trying to create series `id` that already exists.
  * 
  * @param id identifier of the NFT being referenced
  */
  error IERC1155_EXISTANT_TOKEN(uint256 id);
  /**
  * @dev Thrown when `from` tries to transfer more than they own.
  * 
  * @param from address that the NFT are being transferred from
  * @param id identifier of the NFT being referenced
  * @param balance amount of tokens that the address owns
  */
  error IERC1155_INSUFFICIENT_BALANCE(address from, uint256 id, uint256 balance);
  /**
  * @dev Thrown when operator tries to approve themselves for managing a token they own.
  */
  error IERC1155_INVALID_CALLER_APPROVAL();
  /**
  * @dev Thrown when a token is being transferred to the zero address.
  */
  error IERC1155_INVALID_TRANSFER();
  /**
  * @dev Thrown when the requested token doesn"t exist.
  * 
  * @param id identifier of the NFT being referenced
  */
  error IERC1155_NON_EXISTANT_TOKEN(uint256 id);
  /**
  * @dev Thrown when a token is being safely transferred to a contract unable to handle it.
  * 
  * @param receiver address unable to receive the token
  */
  error IERC1155_NON_ERC1155_RECEIVER(address receiver);
  /**
  * @dev Thrown when an ERC1155Receiver contract rejects a transfer.
  */
  error IERC1155_REJECTED_TRANSFER();
}