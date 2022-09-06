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

contract MutantCandy is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPer;
  bool isStart = false;
  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_

  ) ERC721A("MutantCandy", "MutantCandy", maxBatchSize_, collectionSize_) {
    maxPer = maxBatchSize_;
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  uint256 price = 6800000000000000;

  function publicSaleMint(uint8 quantity)
    external
    payable
    callerIsUser
  {  
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPer,
      "can not mint this many"
    );
    uint256 totalprice;
    if(numberMinted(msg.sender)<1){
      totalprice = (quantity - 1) * price;
    }else{
      totalprice = quantity  * price;
    }
    _safeMint(msg.sender, quantity);
    refundIfOver(totalprice);
  }

  function refundIfOver(uint256 cost) private {
    require(msg.value >= cost, "Need to send more ETH.");
    if (msg.value > cost) {
      payable(msg.sender).transfer(msg.value - cost);
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

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
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