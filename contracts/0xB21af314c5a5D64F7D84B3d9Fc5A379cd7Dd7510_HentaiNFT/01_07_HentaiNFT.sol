// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HentaiNFT is Ownable, ERC721A, ReentrancyGuard {
  uint256 public constant maxBatchSize = 10;
  uint256 public constant maxDevMint = 20;
  uint256 public constant collectionSize = 450;
  uint256 public constant publicPrice = 45000000000000000; // 0.045 ETH
  string private _baseTokenURI;

  constructor() ERC721A("Hentaitown NFT", "HENTAITOWN") {
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(quantity <= maxBatchSize, "mint in smaller batches");
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(numberMinted(msg.sender) + quantity <= maxDevMint, "can not mint this many");
    _safeMint(msg.sender, quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

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

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return _ownershipOf(tokenId);
  }
}