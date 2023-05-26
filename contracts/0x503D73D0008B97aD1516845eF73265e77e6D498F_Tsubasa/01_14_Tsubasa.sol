// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AOwnersExplicit.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/***

,---------.   .-'''-.   ___    _  _______      ____       .-'''-.    ____     
\          \ / _     \.'   |  | |\  ____  \  .'  __ `.   / _     \ .'  __ `.  
 `--.  ,---'(`' )/`--'|   .'  | || |    \ | /   '  \  \ (`' )/`--'/   '  \  \ 
    |   \  (_ o _).   .'  '_  | || |____/ / |___|  /  |(_ o _).   |___|  /  | 
    :_ _:   (_,_). '. '   ( \.-.||   _ _ '.    _.-`   | (_,_). '.    _.-`   | 
    (_I_)  .---.  \  :' (`. _` /||  ( ' )  \.'   _    |.---.  \  :.'   _    | 
   (_(=)_) \    `-'  || (_ (_) _)| (_{;}_) ||  _( )_  |\    `-'  ||  _( )_  | 
    (_I_)   \       /  \ /  . \ /|  (_,_)  /\ (_ o _) / \       / \ (_ o _) / 
    '---'    `-...-'    ``-'`-'' /_______.'  '.(_,_).'   `-...-'   '.(_,_).'  
  ___        _____     _    _          _       _   _ _   _ 
 | _ )_  _  |_   _|_ _| |__(_)_ _  ___| |_____| |_(_) |_(_)
 | _ \ || |   | |/ _` | '_ \ | ' \/ -_) / / _ \ / / | / / |
 |___/\_, |   |_|\__,_|_.__/_|_||_\___|_\_\___/_\_\_|_\_\_|
      |__/                                                 

***/

contract Tsubasa is Ownable, ERC721A, ERC721AOwnersExplicit, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint = 4;
  uint256 public immutable maxSupply = 8888;

  uint256 public auctionSaleStartTime;
  uint256 public maxAuctionSupply = 8888;
  
  uint256 public whitelistPrice;

  uint256 public AUCTION_PRICE_CURVE_LENGTH = 2 hours;
  uint256 public AUCTION_START_PRICE = 0.6 ether;
  uint256 public AUCTION_END_PRICE = 0.15 ether;
  uint256 public constant AUCTION_DROP_INTERVAL = 3 minutes;

  bool public dutchAuctionActive = false;
  bool public privateSaleActive = false;

  mapping(address => bool) public allowlist;

  address public constant DEV_VAULT = 0xD7eA15baE263CE4a7B6a26a4853cEc3C670cFC07;
  address public constant DEV_ADDRESS_1 = 0x2D7BFbA6e49c9cd451C44d27775725fc56F3B044;
  address public constant DEV_ADDRESS_2 = 0xccf0A6F45f98ce923A5091ec9Af3c61f99DB15CF; 
  address public constant DEV_ADDRESS_3 = 0x936F0bD56dcA96E5CC7FBA7448a7aEE9fb9d87eE; 
  address public constant DEV_ADDRESS_4 = 0x658406EF6C804B6A83a092D58A2B269d3944e2A8; 

  constructor() ERC721A("Tsubasa", "TSUBASA") {}

  function auctionMint(uint256 quantity) external payable {
    require(dutchAuctionActive, "Dutch auction not active");
    require(auctionSaleStartTime != 0 && block.timestamp >= auctionSaleStartTime, "sale has not started yet");
    require(totalSupply() + quantity <= maxAuctionSupply, "not enough remaining reserved for auction to support desired mint amount");
    require(quantity <= maxPerAddressDuringMint, "Quantity exceeds maxPerAddressDuringMint");
    uint256 totalCost = getAuctionPrice() * quantity;
    require(msg.value >= totalCost, "not enough eth");
  
    _safeMint(msg.sender, quantity);
  }

  function allowlistMint() external payable {
    require(privateSaleActive, "Private sale not active");
    require(allowlist[msg.sender], "not eligible for allowlist mint");
    require(msg.value >= whitelistPrice, "not enough eth");
    require(totalSupply() + 1 <= maxSupply, "reached max supply");
    allowlist[msg.sender] = false;
    _safeMint(msg.sender, 1);
  }

  function getAuctionPrice() public view returns (uint256) {
    uint256 AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);
    if (block.timestamp < auctionSaleStartTime) {
      return AUCTION_START_PRICE;
    }

    if (block.timestamp - auctionSaleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
      return AUCTION_END_PRICE;
    } else {
      uint256 steps = (block.timestamp - auctionSaleStartTime) / AUCTION_DROP_INTERVAL;
      return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
    }
  }

  function setAuctionStartAndSupply(uint256 startTime, uint256 _maxAuctionSupply) external onlyOwner {
    auctionSaleStartTime = startTime;
    maxAuctionSupply = _maxAuctionSupply;
  }
  
  function setAuctionDetails(uint256 _AUCTION_PRICE_CURVE_LENGTH, 
    uint256 _AUCTION_START_PRICE, uint256 _AUCTION_END_PRICE) external onlyOwner {
    AUCTION_PRICE_CURVE_LENGTH = _AUCTION_PRICE_CURVE_LENGTH;
    AUCTION_START_PRICE = _AUCTION_START_PRICE;
    AUCTION_END_PRICE = _AUCTION_END_PRICE;
  }
  
  function setPrivateSaleActive(bool _privateSaleActive) external onlyOwner {
    if(_privateSaleActive) {
      require(whitelistPrice > 0, "whitelist price must be set first");
    }
    privateSaleActive = _privateSaleActive;
  }

  function setDutchAuctionActive(bool _dutchAuctionActive) external onlyOwner {
    dutchAuctionActive = _dutchAuctionActive;
  }

  function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
    whitelistPrice = _whitelistPrice;
  }

  function seedAllowlist(address[] memory addresses, bool allow) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = allow;
    }
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= maxSupply, "reached max supply");
    for (uint256 i = 0; i < quantity; i++) {
      _safeMint(msg.sender, 1);
    }
  }

  // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "Balance is 0");
    payable(DEV_VAULT).transfer(balance * 4000 / 10000);
    payable(DEV_ADDRESS_1).transfer(balance * 650 / 10000);
    payable(DEV_ADDRESS_2).transfer(balance * 1800 / 10000);
    payable(DEV_ADDRESS_3).transfer(balance * 1800 / 10000);
    payable(DEV_ADDRESS_4).transfer(address(this).balance);
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }

  function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index = 0;
      for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
          if (index == tokenCount) break;

          if (ownerOf(tokenId) == _owner) {
              result[index] = tokenId;
              index++;
          }
      }

      return result;
    }
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory ) {
    return this.tokensOfOwner(_owner, 0, maxSupply);
  }
}