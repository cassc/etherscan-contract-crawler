// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//----------------------------------------------------------------------
//     __  _______  ____  ______
//    /  |/  / __ \/ __ \/ ____/
//   / /|_/ / /_/ / /_/ / /     
//  / /  / / ____/ ____/ /___   
// /_/  /_/_/   /_/    \____/   
//
// Manila Pool Party Club is an Exclusive NFT Club and the First & Only 
// NFT project that showcases the Philippines as a world class tourist 
// destination.
//
// https://linktr.ee/mppcnft
//
//----------------------------------------------------------------------

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "erc721b/contracts/ERC721B.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MPPC is 
  Ownable, 
  AccessControl, 
  ReentrancyGuard, 
  ERC721B, 
  IERC721Metadata 
{
  using Strings for uint256;
  
  // ============ Constants ============

  //roles
  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant _CURATOR_ROLE = keccak256("CURATOR_ROLE");
  bytes32 private constant _APPROVED_ROLE = keccak256("APPROVED_ROLE");
  
  //bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  
  //max amount that can be minted in this collection
  uint16 public constant MAX_SUPPLY = 9000;

  //immutable preview uri json
  string private _PREVIEW_URI;
  //contract URI
  string private _CONTRACT_URI;

  // ============ Storage ============

  //mapping of address to amount minted
  mapping(address => uint256) public minted;
  //flag for if the sales has started
  bool public saleStarted;
  //base URI
  string private _baseTokenURI;
  //maximum amount that can be purchased per wallet in the public sale
  uint256 public maxPerWallet = 2;
  //the sale price per token
  uint256 public mintPrice = 0.025 ether;
  //where 10000 == 100.00%
  uint256 public creatorFees = 1000;
  
  //the treasury
  address public treasury;

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
   * @dev Returns the contract URI.
   */
  function contractURI() external view returns(string memory) {
    return _CONTRACT_URI;
  }

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
   * @dev Returns the token collection name.
   */
  function name() external pure returns(string memory) {
    return "Manila Pool Party Club";
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external pure returns(string memory) {
    return "MPPC";
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns(string memory) {
    if(!_exists(tokenId)) revert InvalidCall();
    return bytes(_baseTokenURI).length > 0 ? string(
      abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json")
    ) : _PREVIEW_URI;
  }

  // ============ Write Methods ============

  /**
   * @dev Creates a new token for the `recipient`. Its token ID will be 
   * automatically assigned
   */
  function mint(uint256 quantity) external payable nonReentrant {
    address recipient = _msgSender();
    //no contracts sorry..
    if (recipient.code.length > 0
      //has the sale started?
      || !saleStarted
      //the quantity here plus the current amount already minted 
      //should be less than the max purchase amount
      || (quantity + minted[recipient]) > maxPerWallet
      //the value sent should be the price times quantity
      || (quantity * mintPrice) > msg.value
      //the quantity being minted should not exceed the max supply
      || (totalSupply() + quantity) > MAX_SUPPLY
    ) revert InvalidCall();

    minted[recipient] += quantity;
    _safeMint(recipient, quantity);
  }

  /**
   * @dev Allows anyone to mint a token that was approved by the owner
   */
  function mint(
    uint256 quantity,
    uint256 maxMint, 
    bytes memory proof
  ) external payable nonReentrant {
    address recipient = _msgSender();

    //the quantity here plus the current amount already minted 
    //should be less than the max purchase amount
    if ((quantity + minted[recipient]) > maxMint
      //the value sent should be the price times quantity
      || (quantity * mintPrice) > msg.value
      //the quantity being minted should not exceed the max supply
      || (totalSupply() + quantity) > MAX_SUPPLY
      //make sure the minter signed this off
      || !hasRole(_MINTER_ROLE, ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked("mint", recipient, maxMint))
        ),
        proof
      ))
    ) revert InvalidCall();

    minted[recipient] += quantity;
    _safeMint(recipient, quantity);
  }

  /** 
   * @dev ERC165 bytes to add to interface array - set in parent contract
   *  implementing this standard
   */
  function royaltyInfo(
    uint256 tokenId,
    uint256 salePrice
  ) external view returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    if (treasury == address(0) || !_exists(tokenId)) 
      revert InvalidCall();
    
    return (
      payable(treasury), 
      (salePrice * creatorFees) / 10000
    );
  }

  // ============ Admin Methods ============

  /**
   * @dev Allows the _MINTER_ROLE to mint any to anyone (in the case of 
   * a no sell out)
   */
  function mint(
    address recipient,
    uint256 quantity
  ) external onlyRole(_MINTER_ROLE) nonReentrant {
    //the quantity being minted should not exceed the max supply
    if ((totalSupply() + quantity) > MAX_SUPPLY) revert InvalidCall();

    _safeMint(recipient, quantity);
  }

  /**
   * @dev Setting base token uri would be acceptable if using IPFS CIDs
   */
  function setBaseURI(string memory uri) external onlyRole(_CURATOR_ROLE) {
    _baseTokenURI = uri;
  }
  
  /**
   * @dev Sets a new max per wallet
   */
  function setMaxPerWallet(uint256 max) external onlyRole(_CURATOR_ROLE) {
    maxPerWallet = max;
  }

  /**
   * @dev Sets a new mint price
   */
  function setMintPrice(uint256 price) external onlyRole(_CURATOR_ROLE) {
    mintPrice = price;
  }

  /**
   * @dev Sets a new teasury location
   */
  function setTreasury(address recipient) external onlyRole(_CURATOR_ROLE) {
    //can only be a contract
    if (recipient.code.length == 0) revert InvalidCall();
    treasury = recipient;
  }

  /**
   * @dev Sets the contract URI
   */
  function setURI(string memory uri) external onlyRole(_CURATOR_ROLE) {
    _CONTRACT_URI = uri;
  }

  /**
   * @dev Starts the sale
   */
  function startSale(bool yes) external onlyRole(_CURATOR_ROLE) {
    saleStarted = yes;
  }

  /**
   * @dev Updates the creator fees
   */
  function updateFees(uint256 percent) external onlyRole(_CURATOR_ROLE) {
    if (percent > 1000) revert InvalidCall();
    creatorFees = percent;
  }
  
  /**
   * @dev Allows the proceeds to be withdrawn. This wont be allowed
   * until the collection is released to discourage rug pulls
   */
  function withdraw(PaymentSplitter splitter) external onlyOwner nonReentrant {
    //cannot withdraw without setting a base URI first
    if (bytes(_baseTokenURI).length == 0) revert InvalidCall();
    payable(splitter).transfer(address(this).balance);
  }

  // ============ Linear Overrides ============

  /**
   * @dev Linear override for `supportsInterface` used by `AccessControl`
   *      and `ERC721B`
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
}