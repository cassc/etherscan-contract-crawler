// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./ERC721A.sol";

contract MferSimpson is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
  uint256 public constant AMOUNT_FOR_TEAM   = 23;
  uint256 public constant COLLECTION_SIZE   = 1234;

  uint256 public          maxPerMint        = 123;
  uint256 public          mintPrice         = 0.0234 ether;
  
  uint256 public          nextOwnerToExplicitlySet;
  string public           baseURI;

  bool public             isMintActive;

  constructor(
    address[] memory payees_,
    uint256[] memory shares_
  )
    ERC721A("mfersimpson", "mfsimp") 
    PaymentSplitter(payees_, shares_)
  {}

  modifier verifyTx(uint256 quantity) {
    require(
      msg.sender == tx.origin, 
      "Only sender can execute this transaction!"
    );
    
    require(
      quantity < maxPerMint + 1, 
      "Minted amount exceeds mint limit!"
    );

    require(
      totalSupply() + quantity < COLLECTION_SIZE - AMOUNT_FOR_TEAM + 1, 
      "SOLD OUT!"
    );

    require(
      msg.value == mintPrice * quantity, 
      "Need to send the exact amount!"
    );
    _;
  }

  function mint(uint256 quantity)
    external
    payable
    verifyTx(quantity)    
  {
    require(isMintActive, "Mint is not active");

    _safeMint(msg.sender, quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setCost(uint256 _newCost) external onlyOwner {
      mintPrice = _newCost;
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
  
  function flipMintState() external onlyOwner {
      isMintActive = !isMintActive;
  }

  /**
    * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
    */
  function _setOwnersExplicit(uint256 quantity) internal {
      require(quantity != 0, "quantity must be nonzero");
      require(currentIndex != 0, "no tokens minted yet");
      uint256 _nextOwnerToExplicitlySet = nextOwnerToExplicitlySet;
      require(_nextOwnerToExplicitlySet < currentIndex, "all ownerships have been set");

      // Index underflow is impossible.
      // Counter or index overflow is incredibly unrealistic.
      unchecked {
          uint256 endIndex = _nextOwnerToExplicitlySet + quantity - 1;

          // Set the end index to be the last token index
          if (endIndex + 1 > currentIndex) {
              endIndex = currentIndex - 1;
          }

          for (uint256 i = _nextOwnerToExplicitlySet; i <= endIndex; i++) {
              if (_ownerships[i].addr == address(0)) {
                  TokenOwnership memory ownership = ownershipOf(i);
                  _ownerships[i].addr = ownership.addr;
                  _ownerships[i].startTimestamp = ownership.startTimestamp;
              }
          }

          nextOwnerToExplicitlySet = endIndex + 1;
      }
  }
}