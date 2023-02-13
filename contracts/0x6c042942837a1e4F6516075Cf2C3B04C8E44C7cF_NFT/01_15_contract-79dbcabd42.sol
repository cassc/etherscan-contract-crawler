// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT is ERC721, Ownable, ERC721Enumerable {
  using Counters for Counters.Counter;

  uint256 public constant MAX_SUPPLY = 333;
  uint256 public constant USER_LIMIT = 3;
  uint256 public constant MINT_PRICE = 0.0088 ether;
  bool public isSaleActive = false;

  Counters.Counter private currentTokenId;

  string public baseTokenURI;

  constructor() ERC721("GESTURE", "WG") {
    baseTokenURI = "ipfs://QmQEomzHsKwvFR5SCcbHdZpSgRcfh24odyhojF476PH5VE/";
  }

  function _safeMint(address to) private {
    currentTokenId.increment();
    uint256 newItemId = currentTokenId.current();
    _safeMint(to, newItemId);
  }

  function mint(uint256 mintAmount) public payable{
    require(isSaleActive, "Sale is not active" );
    require(USER_LIMIT > 0, "Minimum one amount");
    require(balanceOf(msg.sender) + mintAmount <= USER_LIMIT, "I'm sorry only three NFT per user");

    uint256 tokenId = currentTokenId.current();
    require(tokenId + mintAmount < MAX_SUPPLY, "Max supply reached");
    require(msg.value == MINT_PRICE * mintAmount, "Transaction value did not equal the mint price");


    for(uint256 i; i < mintAmount; i++){
        _safeMint(msg.sender);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function withdrawMoneyTo(address payable _to) public onlyOwner{
    _to.transfer(address(this).balance);
  }
  
  function setIsActive(bool isActive) public onlyOwner{
    isSaleActive = isActive;
  } 

  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}