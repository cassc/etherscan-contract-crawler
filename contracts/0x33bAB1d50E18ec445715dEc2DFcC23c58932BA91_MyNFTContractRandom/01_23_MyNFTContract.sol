//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


// Overview of contract capability
// Standard ERC721
// Supports for:
// - Presale list
// - Admin other than Owner
// - Burnable

contract MyNFTContract is Context,  AccessControlEnumerable, ERC721Enumerable, ERC721URIStorage{
  using Counters for Counters.Counter;
  Counters.Counter public _tokenIdTracker;

  string private _baseTokenURI;
  /// @notice Mint price
  uint private _price;
  /// @notice Mint price for presale
  uint private _presaleprice;
  /// @notice Max number of token mintable
  uint private _max;
  address _wallet;

  bool _openMint;
  bool _openWhitelistMint;

  mapping(address => bool) private whitelist;

  constructor(string memory name, string memory symbol, string memory baseTokenURI, uint mintPrice, uint mintPreSalePrice, uint max, address wallet, address admin) ERC721(name, symbol) {
      _baseTokenURI = baseTokenURI;
      _price = mintPrice;
      _presaleprice = mintPreSalePrice;
      _max = max;
      _wallet = wallet;
      _openMint = false;
      _openWhitelistMint = false;
      _setupRole(DEFAULT_ADMIN_ROLE, wallet);
      _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to change base URI");
    _baseTokenURI = baseURI;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to change token URI");
    _setTokenURI(tokenId, _tokenURI);
  }

  /**
    @notice Method for updating minting fee
    @dev Only admin
    @param mintPrice uint the minting fee to set
    */
  function setPrice(uint mintPrice) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to change price");
    _price = mintPrice;
  }

  function setPreSalePrice(uint mintPreSalePrice) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to change presale price");
    _presaleprice = mintPreSalePrice;
  }

  function setMax(uint max) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to change the max quantity");
    _max = max;
  }

  function setMint(bool openMint, bool openWhitelistMint) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to open/close mint");
    _openMint = openMint;
    _openWhitelistMint = openWhitelistMint;
  }

  function getPrice() public view returns (uint) {
    return _price;
  }

  function getPreSalePrice() public view returns (uint) {
    return _presaleprice;
  }

  function getMax() public view returns (uint) {
    return _max;
  }

  function mint(uint amount) public payable {
    require(amount <= 10, "Max of 10 NFT per mint");
    require(_openMint == true, "Minting is closed");
    require(msg.value == _price*amount, "Must send correct price");
    require(_tokenIdTracker.current() + amount <= _max, "Not enough NFT left to be minted");
    for(uint i = 0; i < amount; i++) {
      _mint(msg.sender, _tokenIdTracker.current());
      _tokenIdTracker.increment();
    }
    payable(_wallet).transfer(msg.value);
  }

  function mintWhitelist() public payable {
    require(_openWhitelistMint == true, "Minting is closed");
    require(whitelist[msg.sender] == true, "User must be whitelisted to mint");
    require(msg.value == _presaleprice, "Must send correct price");
    require(_tokenIdTracker.current() < _max, "All NFTs have been minted");
    
    whitelist[msg.sender] = false;
    _mint(msg.sender, _tokenIdTracker.current());
    _tokenIdTracker.increment();
    payable(_wallet).transfer(msg.value);
  }

  function whitelistUser(address user) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to whitelist address");
    whitelist[user] = true;
  }

  function whitelistStatus(address user) public view returns(bool) {
    return whitelist[user];
  }

  function burn(uint256 tokenId) public{
    require(_isApprovedOrOwner(msg.sender, tokenId), "Must own the token to burn it");
    _burn(tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    return ERC721URIStorage._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return ERC721URIStorage.tokenURI(tokenId);
  }
  
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}