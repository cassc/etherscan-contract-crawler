// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @title ERC-721 Non-Fungible Token Standard
* @dev See https://eips.ethereum.org/EIPS/eip-721
*  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
*/
interface IERC721 /* is IERC165 */ {
  /**
  * @dev This emits when the approved address for an NFT is changed or reaffirmed.
  *   The zero address indicates there is no approved address.
  *   When a Transfer event emits, this also indicates that the approved address for that NFT (if any) is reset to none.
  * 
  * @param owner address that owns the token
  * @param approved address that is allowed to manage the token
  * @param tokenId identifier of the token being approved
  */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  /**
  * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage all NFTs of the owner.
  * 
  * @param owner address that owns the tokens
  * @param operator address that is allowed or not to manage the tokens
  * @param approved whether the operator is allowed or not
  */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  /**
  * @dev This emits when ownership of any NFT changes by any mechanism.
  *   This event emits when NFTs are created (`from` == 0) and destroyed (`to` == 0).
  *   Exception: during contract creation, any number of NFTs may be created and assigned without emitting Transfer.
  *   At the time of any transfer, the approved address for that NFT (if any) is reset to none.
  * 
  * @param from address the token is being transferred from
  * @param to address the token is being transferred to
  * @param tokenId identifier of the token being transferred
  */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
  * @notice Change or reaffirm the approved address for an NFT
  * @dev The zero address indicates there is no approved address.
  *   Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
  */
  function approve(address approved_, uint256 tokenId_) external;
  /**
  * @notice Transfers the ownership of an NFT from one address to another address
  * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
  *   Throws if `from_` is not the current owner.
  *   Throws if `to_` is the zero address.
  *   Throws if `tokenId_` is not a valid NFT.
  *   When transfer is complete, this function checks if `to_` is a smart contract (code size > 0).
  *   If so, it calls {onERC721Received} on `to_` and throws if the return value is not
  *   `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  */
  function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes calldata data_) external;
  /**
  * @notice Transfers the ownership of an NFT from one address to another address
  * @dev This works identically to the other function with an extra data parameter,
  *   except this function just sets data to "".
  */
  function safeTransferFrom(address from_, address to_, uint256 tokenId_) external;
  /**
  * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets.
  * @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
  */
  function setApprovalForAll(address operator_, bool approved_) external;
  /**
  * @notice Transfer ownership of an NFT.
  *   The caller is responsible to confirm that `to_` is capable of receiving nfts or
  *   else they may be permanently lost
  * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
  *   Throws if `from_` is not the current owner.
  *   Throws if `to_` is the zero address.
  *   Throws if `tokenId_` is not a valid NFT.
  */
  function transferFrom(address from_, address to_, uint256 tokenId_) external;

  /**
  * @notice Count all NFTs assigned to an owner
  * @dev NFTs assigned to the zero address are considered invalid. Throws for queries about the zero address.
  */
  function balanceOf(address owner_) external view returns (uint256);
  /**
  * @notice Get the approved address for a single NFT
  * @dev Throws if `tokenId_` is not a valid NFT.
  */
  function getApproved(uint256 tokenId_) external view returns (address);
  /**
  * @notice Query if an address is an authorized operator for another address
  */
  function isApprovedForAll(address owner_, address operator_) external view returns (bool);
  /**
  * @notice Find the owner of an NFT
  * @dev NFTs assigned to zero address are considered invalid, and queries
  *  about them do throw.
  */
  function ownerOf(uint256 tokenId_) external view returns (address);
}