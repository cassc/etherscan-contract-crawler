// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FrahmFlowCollection is ERC721A, Ownable, ReentrancyGuard {
  uint256 public constant AMOUNT_FOR_DEV = 6;
  uint256 public constant MAX_COLLECTION_SIZE = 66;
  uint256 public constant MAX_MINTS_PER_TX = 3;
  uint256 public constant MINT_PRICE = 0.08 ether;

  string private _baseTokenURI = 'https://api.frahm.art/drops/metadata/';

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  constructor() ERC721A("Frahm Flow Collection", "FRAHMFC") {}

  function frahmMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= AMOUNT_FOR_DEV,
      "too many already minted before frahm mint"
    );
    _safeMint(msg.sender, quantity);
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(quantity <= MAX_MINTS_PER_TX, "can only mint 3 per tx");
    require(totalSupply() + quantity <= MAX_COLLECTION_SIZE, "reached max supply");
    _safeMint(msg.sender, quantity);
    refundIfOver(MINT_PRICE * quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "need to send more ETH");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success,) = msg.sender.call{value : address(this).balance}("");
    require(success, "Transfer failed.");
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
}