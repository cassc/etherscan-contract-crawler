// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
interface ContractInterface {
    function ownerOf(uint256 tokenId) external payable returns(address);
    
}

contract OM is Ownable, ERC721A, ReentrancyGuard {
  mapping(address => bool) public mysteryList;
  mapping(address => bool) public publicMinted;
  uint256 publicMintTime;
  uint256 mysteryListMintTime;
  

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_

  ) ERC721A("ORIENTAL MYSTERY", "OM", maxBatchSize_, collectionSize_) {
    
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  
  function devMint(uint8 quantity) external onlyOwner {
     require(
       quantity % maxBatchSize == 0,
       "can only mint a multiple of the maxBatchSize"
     );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint8 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function publicMint()
    external
    callerIsUser
  { 
    require(publicMintTime < block.timestamp ,"not start "); 
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(publicMinted[msg.sender] == false,"can not mint again");
    publicMinted[msg.sender] = true;
     _safeMint(msg.sender, 1);
  }
  function mysteryListMint()
    external
    callerIsUser
  { 
    require(mysteryListMintTime < block.timestamp,"not start "); 
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(mysteryList[msg.sender] == true, "not eligible for mysterylist mint");
    mysteryList[msg.sender] = false;
    _safeMint(msg.sender, 1);
    
  }
  function setMysteryListMintTime(uint256 _time) public onlyOwner {
    mysteryListMintTime = _time;
  }

  function setPublicMintTime(uint256 _time) public onlyOwner {
    publicMintTime = _time;
  }
  
  function seedMysterylist(address[] memory addresses)
    external
    onlyOwner
  {  
    for (uint256 i = 0; i < addresses.length; i++) {
      mysteryList[addresses[i]] = true;
    }
  }
  // // metadata URI
  string private _baseTokenURI;

 
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
 
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }


  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}