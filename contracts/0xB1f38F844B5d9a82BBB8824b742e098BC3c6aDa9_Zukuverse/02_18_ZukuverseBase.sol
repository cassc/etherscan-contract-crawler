//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { PaymentSplitter } from "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import { ERC2981ContractWideRoyalties, ERC2981Base } from "./eip2981/ERC2981ContractWideRoyalties.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";


/**
 * @notice this error will output if a function requires an admin 
  */
error ZukuverseBase__NOTADMIN();

/**
 * @title The base contract for the Zukuverse contract
 * @author NazaWeb Team
 * @notice this contract contains the base functionalities for the NFT mint
 * @dev Marked as abstract as it is a branch of the Main Zukuverse Contract
 */
abstract contract ZukuverseBase is
  PaymentSplitter,
  ERC721A,
  ERC2981ContractWideRoyalties,
  ReentrancyGuard,
  Ownable
{
  /**
   * @notice reveal state determines the reveal of the NFT art
   */
  bool public reveal = false;

  /**
   * @notice baseURI stores the main uri for the NFT metadata 
   */
  string public baseURI;

  /**
   * @notice mapping connects a wallet address to its role as an admin or not
   */

  mapping(address => bool) public isAdmin;

  /**
   * @notice checks on certain function calls if adr is apart of admin or not 
   * @dev utilizing revert instead of require to save on gas per transaction
   */
  modifier onlyAdmin() {
    if (!isAdmin[msg.sender] && msg.sender != owner())
      revert ZukuverseBase__NOTADMIN();
    _;
  }


   /**
    * @notice this constructor implements initial values and function executions 
    * @dev PaymentSplitter and ERC721A are initialized here for main Zuku contract to access
    * @param _payees is an array of wallet addresses that will have the funds split between them
    * @param _shares is an array of how many shares each payee will have determing their creator earnings 
    * @param _name is the name of the NFT Collection
    * @param _symbol is the symbol of the NFT Collection 
    * @param _uri  is the base url to the NFT metadta 
     */
   constructor(
    address[] memory _payees,
    uint256[] memory _shares,
    string memory _name,
    string memory _symbol,
    string memory _uri
   ) PaymentSplitter(_payees, _shares) ERC721A(_name, _symbol) {
     baseURI = _uri;
  }

/**
 * @notice this functions sets admin(s) for wallet addresses 
 * @dev only owner has the ability to set admin
 * @param _addr is the adress passed in to connect
 */
  function setAdmin(address _addr) public onlyOwner {
    isAdmin[_addr] = true;
  }

/**
 * @notice this functions remove admin(s) for wallet addresses 
 * @dev only owner has the ability to set admin
 * @param _addr is the adress passed in to connectz
 */
  function removeAdmin(address _addr) external onlyOwner {
    isAdmin[_addr] = false;
  }


/**
 * @notice sets reveal state 
 * @dev only admin can set 
 * @param _reveal is bool valuepassed to the function to update reveal status 
 */
  function setReveal(bool _reveal) external onlyAdmin {
    reveal = _reveal;
  }

  /**
   *  @notice setsRoyalites for owner and people on OG or Gem list
   * @dev utilizing the erc-2981 contract standar for royalties. only owner can set
   * @param _receiver is the account whom recieves the address of who gets royalties
   */
  function setRoyalties(address _receiver, uint256 _percentage)
    external
    onlyOwner
  {
    _setRoyalties(_receiver, _percentage);
  }
  
 /**
 * @notice this function allows admin to update baseURI
 * @dev only owner has the ability to set admin
 * @param _uri is the adress passed in to connectz
 */
  function setURI(string memory _uri) external onlyAdmin {
    baseURI = _uri;
  }

 /**
  * @notice function gives access to the base URI for metadata 
  * @dev overrides the baseURI function in erc721a implementation 
  * @return baseURI for access of metadata 
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

 /**
  * @notice function gives us access to the total number of tokens minted between wallets 
  * @dev utilizing _numberMinted internal function from erc721a smart contract to get access
  * @param owner refers to the address we are querying 
  * @return Total NFTs minted by a user
  */
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }


  /**
   * @notice tokenURI gives us the full URI to a specific NFT's metadata 
   * @dev is an override of base implemention of Azuki ERC721A 
   * @param tokenId is the id of the NFT metadata we are looking for
   * @return tokenURI which contains NFT info
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI_ = _baseURI();
    return
      bytes(baseURI_).length != 0 && reveal
        ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
        : string(abi.encodePacked(baseURI, "unreveal.json"));
  }

  //Override required by solidity
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981Base)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}