// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC721BAbstract.sol";
import "./IMetadata.sol";
import "./IRoyaltySplitter.sol";

/**
 * @dev Adds access control, metadata, erc2981 and royalties, and 
 * marketplace proxies. Opens set sontract URI
 */
abstract contract CashCowsAbstract is 
  Ownable,
  AccessControl, 
  ERC721BAbstract, 
  IERC721Metadata 
{ 
  // ============ Constants ============

  //roles
  bytes32 internal constant _DAO_ROLE = keccak256("DAO_ROLE");
  bytes32 internal constant _CURATOR_ROLE = keccak256("CURATOR_ROLE");
  bytes32 internal constant _APPROVED_ROLE = keccak256("APPROVED_ROLE");
  
  //bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  //immutable preview uri json
  string private _PREVIEW_URI;

  // ============ Storage ============

  //the treasury where your money at.
  IRoyaltySplitter public treasury;
  //where 10000 == 100.00%
  uint256 public royaltyPercent = 1000;
  //the location of the metadata generator
  IMetadata internal _metadata;

  // ============ Deploy ============

  /**
   * @dev Sets the base token uri
   */
  constructor(string memory preview, address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _PREVIEW_URI = preview;
  }
  
  // ============ Read Methods ============

  /**
   * @dev Override isApprovedForAll to whitelist marketplaces 
   * to enable gas-less listings.
   */
  function isApprovedForAll(
    address owner, 
    address operator
  ) public view override(ERC721B, IERC721) returns(bool) {
    return hasRole(_APPROVED_ROLE, operator) 
      || super.isApprovedForAll(owner, operator);
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(
    uint256 tokenId
  ) external view returns(string memory) {
    //if token does not exist
    if(!_exists(tokenId)) revert InvalidCall();
    //if metadata is not set
    if (address(_metadata) == address(0)) return _PREVIEW_URI;
    return _metadata.tokenURI(tokenId);
  }

  // ============ Write Methods ============

  /** 
   * @dev ERC165 bytes to add to interface array - set in parent contract
   *  implementing this standard
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    if (address(treasury) == address(0) || !_exists(_tokenId)) 
      revert InvalidCall();
    
    return (
      payable(address(treasury)), 
      (_salePrice * royaltyPercent) / 10000
    );
  }

  /**
   * @dev Adding support for ERC2981
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl, ERC721B, IERC165) returns(bool) {
    //support ERC721
    return interfaceId == type(IERC721Metadata).interfaceId
      //support ERC2981
      || interfaceId == _INTERFACE_ID_ERC2981
      //support other things
      || super.supportsInterface(interfaceId);
  }

  // ============ Admin Methods ============

  /**
   * @dev Sets the contract URI
   */
  function setURI(string memory uri) external onlyRole(_CURATOR_ROLE) {
    _setURI(uri);
  }

  /**
   * @dev Updates the metadata location
   */
  function updateMetadata(
    IMetadata metadata
  ) external onlyRole(_CURATOR_ROLE) {
    _metadata = metadata;
  }

  /**
   * @dev Updates the royalty (provisions for Cow DAO) 
   * where `percent` up to 1000 == 10.00%
   */
  function updateRoyalty(uint256 percent) external onlyRole(_DAO_ROLE) {
    if (percent > 1000) revert InvalidCall();
    royaltyPercent = percent;
  }

  /**
   * @dev Updates the treasury location, (in the case treasury needs to 
   * be updated)
   */
  function updateTreasury(IRoyaltySplitter splitter) external onlyRole(_CURATOR_ROLE) {
    treasury = splitter;
  }
}