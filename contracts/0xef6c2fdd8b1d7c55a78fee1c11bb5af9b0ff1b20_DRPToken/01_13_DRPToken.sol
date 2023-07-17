// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//       _____              __                           __
//     _/ ____\_ __   ____ |  | __ __________ __   ____ |  | __
//     \   __\  |  \_/ ___\|  |/ / \___   /  |  \_/ ___\|  |/ /
//      |  | |  |  /\  \___|    <   /    /|  |  /\  \___|    <
//      |__| |____/  \___  >__|_ \ /_____ \____/  \___  >__|_ \
//                       \/     \/       \/           \/     \/
//
//     DRP + Pellar 2021
//     Drop 2 - VR001

contract DRPToken is ERC721Enumerable, Ownable {

  using Strings for uint256;

  // constants
  uint8 public constant MAX_NORMAL_SUPPLY = 88;
  uint8 public constant MAX_FREE_SUPPLY = 176;
  uint8 public constant MAX_NORMAL_PER_ACCOUNT = 1;
  uint8 public constant MAX_TETHER_PER_ACCOUNT = 1;
  uint256 public constant TETHER_PRICE = 0.1 ether;

  // variables
  mapping(address => bool) private winners;
  mapping(uint256 => bool) private claimedFreeToken;
  mapping(uint256 => bool) private claimedTetherToken;
  mapping(address => uint8) private claimedTetherWallet;
  mapping(address => uint8) private claimedNormal;
  uint16 public freeTokenIdx = MAX_NORMAL_SUPPLY;
  uint256 public vrTokenIdx = MAX_FREE_SUPPLY;
  DRP_1 public DROP_1;

  mapping (uint16 => uint16) private randoms;
  uint16 public boundary = MAX_NORMAL_SUPPLY;

  bool public salesActive = false;

  string public baseURI_A1 = "ipfs://Qme1kTg6wxKh9NmBfMkyxvvEDKsUJQWdyjAtMSaC2Fft7f";
  string public baseURI_A2 = "ipfs://QmQm4rwuPBQZqvJAjF5aoPXWPGdPLU598LZ9V7vmbknESg";
  string public baseURI_A3 = "ipfs://QmSi2cD4RnohJB22D6vBYhCBoXPn7uK6VTLrBGb88HDn1H";
  string public baseURI_B = "ipfs://QmfZfrz5YfosYq1KJAUTYY9m4RYSqjBYX8NJf4HCZZbp7S";
  string public baseURI_C = "ipfs://QmfCtJmwUQJNP2NrW5MQ8cuU6Ltm7P1a9qgnsFTScW6CLR";

  constructor() ERC721('DRPToken', 'DRP') {
    DROP_1 = DRP_1(0x0b15727723690295a7981F12CF49b706A3EB555F);
  }

  function toggleActive() external onlyOwner {
    salesActive = !salesActive;
  }

  function setTokenURI(
    string calldata _uri_A1,
    string calldata _uri_A2,
    string calldata _uri_A3,
    string calldata _uri_B,
    string calldata _uri_C
  ) external onlyOwner {
    baseURI_A1 = _uri_A1;
    baseURI_A2 = _uri_A2;
    baseURI_A3 = _uri_A3;
    baseURI_B = _uri_B;
    baseURI_C = _uri_C;
  }

  function addWinners(address[] calldata accounts, bool status) external onlyOwner {
    for (uint256 i = 0; i < accounts.length; i++) {
      winners[accounts[i]] = status;
    }
  }

  function eligiblePrice() public view returns (uint256) {
    uint256 drpBalance = DROP_1.balanceOf(msg.sender);
    if (drpBalance >= 10) {
      return 0.5 ether;
    }
    if (drpBalance >= 5) {
      return 0.7 ether;
    }
    if (drpBalance >= 1) {
      return 1 ether;
    }
    return 0;
  }

  function claim() external payable {
    require(salesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    uint256 price = eligiblePrice();
    require(price > 0, "Claim: Not eligible");
    require(boundary >= 1, "Claim: Sorry, we have sold out.");
    require(msg.value >= (1 * price), "Claim: Ether value incorrect.");
    require(claimedNormal[msg.sender] + 1 <= MAX_NORMAL_PER_ACCOUNT, "Claim: Can not claim that many.");

    uint16 index = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender, totalSupply(), address(this)))) % boundary) + 1; // 1 -> 88
    uint16 tokenId = randoms[index] > 0 ? randoms[index] - 1 : index - 1;
    randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
    boundary = boundary - 1;

    _safeMint(msg.sender, tokenId);
    claimedNormal[msg.sender] = 1;
  }

  function isEligibleTether() public view returns (bool, uint256) {
    uint256 tokenId = MAX_NORMAL_SUPPLY;

    uint256 balance = balanceOf(msg.sender);
    if (balance == 0) return (false, tokenId);

    uint256 drpBalance = DROP_1.balanceOf(msg.sender);

    bool hasNormalToken = false;
    for (uint256 i = 0; i < balance; i++) {
      uint256 id = tokenOfOwnerByIndex(msg.sender, i);
      if (id < MAX_NORMAL_SUPPLY && !claimedTetherToken[id]) {
        hasNormalToken = true;
        tokenId = id;
        break;
      }
    }
    return (hasNormalToken && drpBalance >= 5, tokenId);
  }

  function claimTether() external payable {
    require(salesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    (bool isEligible, uint256 tokenId) = isEligibleTether();
    require(isEligible, "Claim: Not allowed.");
    require(tokenId < MAX_NORMAL_SUPPLY, "Claim: Not allowed.");
    require(!claimedTetherToken[tokenId], "Claim: Token claimed.");
    require(msg.value >= TETHER_PRICE, "Claim: Ether value incorrect.");
    require(claimedTetherWallet[msg.sender] + 1 <= MAX_TETHER_PER_ACCOUNT, "Claim: Can not claim that many.");

    claimedTetherWallet[msg.sender] = 1;
    claimedTetherToken[tokenId] = true;
  }

  function airdrop(uint16 _start, uint16 _end) external onlyOwner {
    require(freeTokenIdx + 1 <= MAX_FREE_SUPPLY, "Claim: Sorry, tokens sold out.");
    for (uint256 tokenId = _start; tokenId < _end; tokenId++) { // loop through token A
      if (_exists(tokenId)) { // check exists ?
        address tokenOwner = ownerOf(tokenId);
        if (!claimedFreeToken[tokenId] && DROP_1.balanceOf(tokenOwner) >= 10) {
          _safeMint(tokenOwner, freeTokenIdx);
          freeTokenIdx += 1;
          claimedFreeToken[tokenId] = true;
        }
      }
    }
  }

  function isEligibleVR() public view returns (bool) {
    return winners[msg.sender];
  }

  function claimVR() external {
    require(salesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    require(isEligibleVR(), "Claim: Not allowed");

    _safeMint(msg.sender, vrTokenIdx);
    vrTokenIdx += 1;
    winners[msg.sender] = false; // just claim once.
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId), "URI query for non existent token");
    if (_tokenId <= 43) {
      return baseURI_A1;
    }
    if (_tokenId <= 76) {
      return baseURI_A2;
    }
    if (_tokenId <= 87) {
      return baseURI_A3;
    }
    if (_tokenId <= 175) {
      return baseURI_B;
    }
    return baseURI_C;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    require(balance > 0, "Contract balance is 0");
    payable(msg.sender).transfer(balance);
  }
}

interface DRP_1 {
  function balanceOf(address owner) external view returns (uint256 balance);
}