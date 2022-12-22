// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC721Errors {
  /**
  * @dev Thrown when `operator` has not been approved to manage `tokenId` on behalf of `tokenOwner`.
  * 
  * @param tokenOwner : address owning the token
  * @param operator   : address trying to manage the token
  * @param tokenId    : identifier of the NFT being referenced
  */
  error IERC721_CALLER_NOT_APPROVED( address tokenOwner, address operator, uint256 tokenId );
  /**
  * @dev Thrown when `operator` tries to approve themselves for managing a token they own.
  * 
  * @param operator : address that is trying to approve themselves
  */
  error IERC721_INVALID_APPROVAL( address operator );
  /**
  * @dev Thrown when a token is being transferred to the zero address.
  */
  error IERC721_INVALID_TRANSFER();
  /**
  * @dev Thrown when a token is being transferred from an address that doesn't own it.
  * 
  * @param tokenOwner : address owning the token
  * @param from       : address that the NFT is being transferred from
  * @param tokenId    : identifier of the NFT being referenced
  */
  error IERC721_INVALID_TRANSFER_FROM( address tokenOwner, address from, uint256 tokenId );
  /**
  * @dev Thrown when the requested token doesn't exist.
  * 
  * @param tokenId : identifier of the NFT being referenced
  */
  error IERC721_NONEXISTANT_TOKEN( uint256 tokenId );
  /**
  * @dev Thrown when a token is being safely transferred to a contract unable to handle it.
  * 
  * @param receiver : address unable to receive the token
  */
  error IERC721_NON_ERC721_RECEIVER( address receiver );
  /**
  * @dev Thrown when trying to get the token at an index that doesn't exist.
  * 
  * @param index : the inexistant index
  */
  error IERC721Enumerable_INDEX_OUT_OF_BOUNDS( uint256 index );
  /**
  * @dev Thrown when trying to get the token owned by `tokenOwner` at an index that doesn't exist.
  * 
  * @param tokenOwner : address owning the token
  * @param index      : the inexistant index
  */
  error IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( address tokenOwner, uint256 index );
}