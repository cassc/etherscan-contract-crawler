// /$$$$$$$$ /$$                  /$$$$$$            /$$                              
//|__  $$__/| $$                 /$$__  $$          | $$                              
//   | $$   | $$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$ | $$  /$$$$$$   /$$$$$$   /$$$$$$$
//   | $$   | $$__  $$ /$$__  $$| $$       /$$__  $$| $$ /$$__  $$ /$$__  $$ /$$_____/
//   | $$   | $$  \ $$| $$$$$$$$| $$      | $$  \ $$| $$| $$  \ $$| $$  \__/|  $$$$$$ 
//   | $$   | $$  | $$| $$_____/| $$    $$| $$  | $$| $$| $$  | $$| $$       \____  $$
//   | $$   | $$  | $$|  $$$$$$$|  $$$$$$/|  $$$$$$/| $$|  $$$$$$/| $$       /$$$$$$$/
//   |__/   |__/  |__/ \_______/ \______/  \______/ |__/ \______/ |__/      |_______/ 
                                                                                  
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TheColors is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor(string memory customBaseURI_) ERC721("TheColors", "TCB") {
    customBaseURI = customBaseURI_;

    allowedMintCountMap[owner()] = 3;
  }

  

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 3;

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    return a >= b ? a : b;
  }

  function allowedMintCount(address minter) public view returns (uint256) {
    if (saleIsActive) {
      return (
        max(allowedMintCountMap[minter], MINT_LIMIT_PER_WALLET) -
        mintCountMap[minter]
      );
    }

    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  

  uint256 public constant MAX_SUPPLY = 2888;

  uint256 public constant MAX_MULTIMINT = 3;

  uint256 public constant PRICE = 7000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    if (allowedMintCount(msg.sender) >= count) {
      updateMintCount(msg.sender, count);
    } else {
      revert(saleIsActive ? "Minting limit exceeded" : "Sale not active");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 3 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.007 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }

  

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance);
  }
}