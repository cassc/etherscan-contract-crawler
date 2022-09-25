// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity 0.8.17;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is IERC165 */ {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer( address indexed from_, address indexed to_, uint256 indexed tokenId_ );

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval( address indexed owner_, address indexed approved_, uint256 indexed tokenId_ );

  /// @dev This emits when an operator is enabled or disabled for an owner.
  ///  The operator can manage all NFTs of the owner.
  event ApprovalForAll( address indexed owner_, address indexed operator_, bool approved_ );

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner_ An address for whom to query the balance
  /// @return The number of NFTs owned by `owner_`, possibly zero
  function balanceOf( address owner_ ) external view returns ( uint256 );

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId_ The identifier for an NFT
  /// @return The address of the owner of the NFT
  function ownerOf( uint256 tokenId_ ) external view returns ( address );

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from_` is
  ///  not the current owner. Throws if `to_` is the zero address. Throws if
  ///  `tokenId_` is not a valid NFT. When transfer is complete, this function
  ///  checks if `to_` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `to_` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  /// @param data_ Additional data with no specified format, sent in call to `to_`
  function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes calldata data_ ) external;

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `to_` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from_` is
  ///  not the current owner. Throws if `to_` is the zero address. Throws if
  ///  `tokenId_` is not a valid NFT.
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  function transferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param approved_ The new approved NFT controller
  /// @param tokenId_ The NFT to approve
  function approve( address approved_, uint256 tokenId_ ) external;

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `msg.sender`'s assets
  /// @dev Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param operator_ Address to add to the set of authorized operators
  /// @param approved_ True if the operator is approved, false to revoke approval
  function setApprovalForAll( address operator_, bool approved_ ) external;

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `tokenId_` is not a valid NFT.
  /// @param tokenId_ The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved( uint256 tokenId_ ) external view returns ( address );

  /// @notice Query if an address is an authorized operator for another address
  /// @param owner_ The address that owns the NFTs
  /// @param operator_ The address that acts on behalf of the owner
  /// @return True if `operator_` is an approved operator for `owner_`, false otherwise
  function isApprovedForAll( address owner_, address operator_ ) external view returns ( bool );
}