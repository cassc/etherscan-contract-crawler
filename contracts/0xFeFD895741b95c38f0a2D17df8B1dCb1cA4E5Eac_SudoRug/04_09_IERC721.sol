// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.10;

import "IERC165.sol";

/**
* @dev Required interface of an ERC721 compliant contract.
*/
interface IERC721 is IERC165 {
  /**
  * @dev Emitted when `tokenId_` token is transferred from `from_` to `to_`.
  */
  event Transfer( address indexed from_, address indexed to_, uint256 indexed tokenId_ );

  /**
  * @dev Emitted when `owner_` enables `approved_` to manage the `tokenId_` token.
  */
  event Approval( address indexed owner_, address indexed approved_, uint256 indexed tokenId_ );

  /**
  * @dev Emitted when `owner_` enables or disables (`approved`) `operator_` to manage all of its assets.
  */
  event ApprovalForAll( address indexed owner_ , address indexed operator_ , bool approved_ );

  /**
  * @dev Gives permission to `to_` to transfer `tokenId_` token to another account.
  * The approval is cleared when the token is transferred.
  *
  * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
  *
  * Requirements:
  *
  * - The caller must own the token or be an approved operator.
  * - `tokenId_` must exist.
  *
  * Emits an {Approval} event.
  */
  function approve( address to_, uint256 tokenId_ ) external;

  /**
  * @dev Safely transfers `tokenId_` token from `from_` to `to_`, checking first that contract recipients
  * are aware of the ERC721 protocol to prevent tokens from being forever locked.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must exist and be owned by `from_`.
  * - If the caller is not `from_`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
  * - If `to_` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
  *
  * Emits a {Transfer} event.
  */
  function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /**
  * @dev Safely transfers `tokenId_` token from `from_` to `to_`.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must exist and be owned by `from_`.
  * - If the caller is not `from_`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
  * - If `to_` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
  *
  * Emits a {Transfer} event.
  */
  function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes calldata data_ ) external;

  /**
  * @dev Approve or remove `operator_` as an operator for the caller.
  * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
  *
  * Requirements:
  *
  * - The `operator_` cannot be the caller.
  *
  * Emits an {ApprovalForAll} event.
  */
  function setApprovalForAll( address operator_, bool approved_ ) external;

  /**
  * @dev Transfers `tokenId_` token from `from_` to `to_`.
  *
  * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
  *
  * Requirements:
  *
  * - `from_` cannot be the zero address.
  * - `to_` cannot be the zero address.
  * - `tokenId_` token must be owned by `from_`.
  * - If the caller is not `from_`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
  *
  * Emits a {Transfer} event.
  */
  function transferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /**
  * @dev Returns the number of tokens in `tokenOwner_`'s account.
  */
  function balanceOf( address tokenOwner_ ) external view returns ( uint256 balance );

  /**
  * @dev Returns the account approved for `tokenId_` token.
  *
  * Requirements:
  *
  * - `tokenId_` must exist.
  */
  function getApproved( uint256 tokenId_ ) external view returns ( address operator );

  /**
  * @dev Returns if the `operator_` is allowed to manage all of the assets of `tokenOwner_`.
  *
  * See {setApprovalForAll}
  */
  function isApprovedForAll( address tokenOwner_, address operator_ ) external view returns ( bool );

  /**
  * @dev Returns the owner of the `tokenId_` token.
  *
  * Requirements:
  *
  * - `tokenId_` must exist.
  */
  function ownerOf( uint256 tokenId_ ) external view returns ( address owner );
}