// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @notice ERC721ATM
/// @dev ERC721A + Trustless Metadata
///      An extension built on ERC721A v3.0.0 with trustless metadata upgrades.
///      ~ upgradable: contract owner can add new metadata contracts,
///                    all tokens use the most recent by default.
///      ~ immutable: token holders can opt-out of metadata updates by
///                   overriding tokens they hold to use any previously set metadata contract.
abstract contract ERC721ATM is ERC721A, Ownable {
  /// allow for new metadata contracts but keep those previously used,
  /// the last entry in the list is the current metadata contract
  address[] public metadataAddressList;

  /// allow for token holders to opt-out of metadata contract updates
  mapping(uint256 => uint256) public metadataOverrides;

  error MissingMetadata();
  error MetadataNumberTooLow();
  error MetadataNumberTooHigh();
  error NotMetadataApprovedOrOwner();

  constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) Ownable() {}

  function _startTokenId() override internal pure virtual returns (uint256) {
    return 1;
  }

  /// @notice update the collection to a new default metadata contract
  /// @param addr the address of the new metadata contract to use
  function setMetadataAddress(address addr) public virtual onlyOwner {
    metadataAddressList.push(addr);
  }

  /// @notice returns the metadata contract address for a given tokenId
  /// @param tokenId the token to check
  /// @return a metadata contract address override or the most recent set
  function getMetadataAddress(uint256 tokenId) public view virtual returns (address) {
    uint256 metadataNumber = metadataAddressList.length;
    if (metadataNumber == 0) revert MissingMetadata();

    uint256 metadataOverride = metadataOverrides[tokenId];
    if (metadataOverride > 0) {
      metadataNumber = metadataOverride;
    }

    return metadataAddressList[metadataNumber - 1];
  }

  /// @notice opt-out of updates for this token, setting to any previously used metadata contract
  /// @param tokenId the token that will have its metadata overridden
  /// @param metadataNumber the metadata contract to use (index in metadataAddressList + 1)
  function setMetadataNumber(uint256 tokenId, uint256 metadataNumber) public virtual {
    uint256 addressCount = metadataAddressList.length;
    if (metadataNumber == 0) revert MetadataNumberTooLow();
    if (metadataNumber > addressCount) revert MetadataNumberTooHigh();
    if (!isApprovedOrOwnerOf(tokenId)) revert NotMetadataApprovedOrOwner();

    metadataOverrides[tokenId] = metadataNumber;
  }

  /// @notice clear override and opt-in to metadata updates for this token
  /// @param tokenId the token that will have its metadata overridden
  function clearMetadataNumber(uint256 tokenId) public virtual {
    if (!isApprovedOrOwnerOf(tokenId)) revert NotMetadataApprovedOrOwner();

    metadataOverrides[tokenId] = 0;
  }

  /// @dev returns whether `_msgSender()` is allowed to manage `tokenId`
  /// @param tokenId the token to check
  function isApprovedOrOwnerOf(uint256 tokenId) internal view virtual returns (bool) {
    address owner = ownerOf(tokenId);
    return _msgSender() == owner
      || _msgSender() == getApproved(tokenId)
      || isApprovedForAll(owner, _msgSender());
  }

}