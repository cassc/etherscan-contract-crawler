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
contract LINEAGGRESSION is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 whitePrice =5000000000000000;
  uint256 publicPrice =10000000000000000;
  uint256 public  startTime;
  mapping(address => bool) public allowList;
  mapping(address => uint8) public allowListNum;
  mapping(address => uint8) public piblicNum;
  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_

  ) ERC721A("LINE AGGRESSION" , "LA", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  function airdrop(address add,uint256 number) external onlyOwner {
    require(totalSupply() + number <= collectionSize, "reached max supply");
    _safeMint(add, number);
  }
  function setStartTime(
    uint32 startTime_
  ) external onlyOwner {
    startTime =  startTime_;
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
  function seedAllowlist(address[] memory addresses)
    external
    onlyOwner
  {  
    for (uint256 i = 0; i < addresses.length; i++) {
      allowList[addresses[i]] = true;
    }
  }
  function publicSaleMint(uint8 quantity)
    external
    payable
    callerIsUser
  {  
    require(
      startTime <= block.timestamp && startTime!=0,
      "public mint is not start"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      piblicNum[msg.sender] + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    piblicNum[msg.sender] = piblicNum[msg.sender] + quantity;
    uint256 totalprice;
    
    totalprice = quantity  * publicPrice;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalprice);
  }
  function whiteListMint(uint8 quantity)
    external
    payable
    callerIsUser
  {  
    require(
      startTime <= block.timestamp && startTime!=0,
      "public mint is not start"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(allowList[msg.sender] == true,"not allow list");
    require(
      allowListNum[msg.sender] + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    allowListNum[msg.sender]=allowListNum[msg.sender] + quantity;
    uint256 totalprice;
    
    totalprice = quantity  * whitePrice;
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

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
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