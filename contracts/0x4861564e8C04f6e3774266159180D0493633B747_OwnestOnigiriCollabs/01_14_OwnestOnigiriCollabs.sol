//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract OwnestOnigiriCollabs is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  string baseURI;
  
  Counters.Counter private _tokenIds;
  
  constructor() ERC721("Ownest x Onigiri Collabs", "OXO") {
    baseURI = "https://api.onigiri.art/ownestxonigiri/";
  }

  /**
   * @dev Mint NFTs
   */
  function airdropNfts(address[] calldata wAddresses) public onlyOwner {
    for (uint i = 0; i < wAddresses.length; i++) {
      _mintSingleNFT(wAddresses[i]);
    }
  }
  
  function mintOOCs(address wAddress, uint256 number) public onlyOwner {
    for (uint i = 0; i < number; i++) {
      _mintSingleNFT(wAddress);
    }
  }

  function _mintSingleNFT(address wAddress) private {
    _tokenIds.increment();
    uint newTokenID = _tokenIds.current();
    _safeMint(wAddress, newTokenID);
  }

  /**
   * @dev Multiple transfers
   */
  function safeBatchTransferFrom(address[] memory fromAddresses, address[] memory toAddresses, uint256[] memory tokenIds) public {
  	require(tokenIds.length == toAddresses.length, "TokenIds length should match toAddresses length"); 
    require(fromAddresses.length == toAddresses.length, "fromAddresses length should match toAddresses length"); 

    for (uint i = 0; i < tokenIds.length; i++) {
      safeTransferFrom(fromAddresses[i], toAddresses[i], tokenIds[i]);
    }
  }


  /**
   * @dev Token owners can burn their tokens
   */
  function burnToken(uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, "Only the token owner can burn it");
    _burn(tokenId);
  }

  function burnMultipleTokens(uint256[] memory tokenIds) public {
    for (uint i = 0; i < tokenIds.length; i++) {
      burnToken(tokenIds[i]);
    }
  }

  /**
   * @dev Owner can change Base Metadata URL
   */
  function setBaseURI(string memory newURI) public onlyOwner {
    baseURI = newURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function getBaseURI() external view returns (string memory) {
    return baseURI;
  }

  function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
    _setTokenURI(tokenId, tokenURI);
  }
}