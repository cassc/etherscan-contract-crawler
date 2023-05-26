// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Parent {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract DoodleBits is ERC721Enumerable, Ownable {
  using SafeMath for uint256;

  uint constant public doodleSupply = 500;
  uint public maxSupply = 3015; // Reserve 15 for 1/1's
  uint constant public freeSupply = 1000;
  uint256 public mintPrice = 0.03 ether; 

  Parent private parent;
  bool public doodleMintStarted = false;
  bool public mintStarted = false;
  uint public doodleBatchLimit = 1;
  uint public freeBatchLimit = 3;
  uint public batchLimit = 10;
  uint public doodleCounter = 0;
  string public baseURI = "";

  mapping(address => uint256) public doodleLimitPerWallet;
  mapping(address => uint256) public limitPerWallet;

  constructor(address parentAddress) ERC721("DoodleBits", "DB") {
    parent = Parent(parentAddress);
  }

  function freeDoodleMint(uint tokensToMint) public payable {
    uint256 supply = totalSupply();
    require(doodleMintStarted, "Mint is not started");
    require(tokensToMint <= doodleBatchLimit, "Not in batch limit");
    require(doodleCounter.add(tokensToMint) < doodleSupply, "Minting exceeds supply");
    uint balance = parent.balanceOf(msg.sender);
    require(balance >= 1, "Insufficient doodle tokens.");
    require(doodleLimitPerWallet[msg.sender].add(tokensToMint) <= doodleBatchLimit, "Too many free mints");
    doodleLimitPerWallet[msg.sender] += tokensToMint;

    for(uint16 i = 1; i <= tokensToMint; i++) {
      doodleCounter++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function mint(uint tokensToMint) public payable {
    uint256 supply = totalSupply();
    require(mintStarted, "Mint is not started");
    require(tokensToMint <= batchLimit, "Not in batch limit");
    require(supply.add(tokensToMint) <= maxSupply.add(doodleCounter), "Minting exceeds supply");

    if (supply >= freeSupply + doodleCounter) {
      require(tokensToMint <= batchLimit, "Exceeds batch limit");
      require(msg.value >= tokensToMint.mul(mintPrice), "Not enough eth sent");
    } else {
      require(tokensToMint <= freeBatchLimit, "Exceeds free batch limit");
      require(limitPerWallet[msg.sender].add(tokensToMint) <= freeBatchLimit, "Too many free mints");
      require(supply.add(tokensToMint) <= freeSupply.add(doodleCounter), "Minting exceeds free supply");
      limitPerWallet[msg.sender] += tokensToMint;
    }

    for(uint16 i = 1; i <= tokensToMint; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function setPrice(uint256 newPrice) public onlyOwner() {
    mintPrice = newPrice;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function _baseURI() internal view override returns (string memory) {
      return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
		baseURI = newBaseURI;
	}

  function startMint() external onlyOwner {
    mintStarted = true;
  }

  function pauseMint() external onlyOwner {
    mintStarted = false;
  }

  function startDoodleMint() external onlyOwner {
    doodleMintStarted = true;
  }

  function pauseDoodleMint() external onlyOwner {
    doodleMintStarted = false;
  }

  function setDoodleBatchLimit(uint newLimit) public onlyOwner {
    doodleBatchLimit = newLimit;
  }

  function setMaxSupply(uint newSupply) public onlyOwner {
    maxSupply = newSupply;
  }

  function reserveTokens(uint256 numberOfMints) public onlyOwner {
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= numberOfMints; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }
}