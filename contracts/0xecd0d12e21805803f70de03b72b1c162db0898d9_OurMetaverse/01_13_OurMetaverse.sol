// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Contract for OurMetaverse NFT.
// Believe that dreams will come true.
contract OurMetaverse is ERC721A, Ownable, ReentrancyGuard {
  string public baseURI;

  bool public started = false;
  bool public bookMinted = false;
  bool public movieMinted = false;

  uint256 public constant MAX_MINT_PER_ADDR = 10;
  uint256 public constant MAX_SUPPLY = 3000;
  uint256 public constant COMMON_PRICE = 0.01 * 10**18; // 0.01 ETH
  uint256 public constant BOOK_PRICE = 30 * 10**18; // 30 ETH
  uint256 public constant MOVIE_PRICE = 600 * 10**18; // 600 ETH
  uint256 public constant GRANT_PRICE = 0.3 * 10**18; // 0.3 ETH
  uint256 public constant BOOK_GRANT_PRICE = 3 * 10**18; // 3 ETH
  uint256 public constant MOVIE_GRANT_PRICE = 30 * 10**18; // 30 ETH

  uint256 public availableRewardBalance = 0;
  uint256 public mintBalance = 0;
  
  address private buyer = address(0);

  mapping(uint256 => string[]) public grantList;
  mapping(uint256 => uint256) public rewardedBalance;

  event Minted(address minter, uint256 amount);
  event BookMinted(address minter);
  event MovieMinted(address minter);
  event RewardReceived(address sender, uint256 balance);

  constructor(string memory initBaseURI) ERC721A("OurMetaverse", "OURM") {
    baseURI = initBaseURI;
  }

  receive() external payable {
    availableRewardBalance += msg.value;
  }

  function grant(uint256 tokenId, string calldata grantTarget) external payable {
    uint256 len = bytes(grantTarget).length;
    require(len > 0 && len <= 128, "Length overflow");
    address holder = ownerOf(tokenId);
    require(holder == msg.sender, "Only holder");
    string[] storage grunts = grantList[tokenId];
    uint256 grantPrice = grunts.length * GRANT_PRICE;
    if (tokenId == 1) {
      grantPrice = grunts.length * BOOK_GRANT_PRICE;
    }
        if (tokenId == 0) {
      grantPrice = grunts.length * MOVIE_GRANT_PRICE;
    }
    require(msg.value >= grantPrice, "Not enough ETH");
    grunts.push(grantTarget);
    availableRewardBalance += msg.value;
  }

  function getGrantsWithToken(uint256 tokenId) external view returns (string[] memory) {
    return grantList[tokenId];
  }

  function init() external onlyOwner {
    _mint(address(this), 2, "", false);
    _safeMint(msg.sender, 598);
    started = true;
  }

  function isStarted() external view returns (bool) {
    return started;
  }

  function buyBookToken() external payable {
    require(started, "Not started");
    require(!bookMinted, "Has minted");
    require(msg.value >= BOOK_PRICE, "Not enough ETH");
    buyer = msg.sender;
    availableRewardBalance += msg.value;
    transferFrom(address(this), msg.sender, 1);
    buyer = address(0);
    bookMinted = true;
    emit BookMinted(msg.sender);
  }

  function buyMovieToken() external payable {
    require(started, "Not started");
    require(!movieMinted, "Has minted");
    require(msg.value >= MOVIE_PRICE, "Not enough ETH");
    buyer = msg.sender;
    availableRewardBalance += msg.value;
    transferFrom(address(this), msg.sender, 0);
    buyer = address(0);
    movieMinted = true;
    emit MovieMinted(msg.sender);
  }

  function mint(uint256 quantity) external payable {
    require(started, "Not started");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply");
    require(
      numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
      "Each address 10 mint"
    );
    uint256 price = COMMON_PRICE * quantity;

    require(msg.value >= price, "Not enough ETH");

    _safeMint(msg.sender, quantity);
    mintBalance += msg.value;
    emit Minted(msg.sender, quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function getAvailableRewardBalance() external view returns (uint256) {
    return availableRewardBalance;
  }

  function getMintBalance() external view returns (uint256) {
    return mintBalance;
  }

  function getRewardBalanceWithToken(uint256 tokenId) public view returns (uint256) {
    uint256 leftBalance = availableRewardBalance % MAX_SUPPLY;
    uint256 availableBalance = availableRewardBalance - leftBalance;
    uint256 availableBalancePerToken = availableBalance / MAX_SUPPLY;
    return availableBalancePerToken - rewardedBalance[tokenId];
  }

  function receiveMintBalance() external onlyOwner nonReentrant {
    uint256 availableBalance = mintBalance;
    mintBalance = 0;
    (bool success, ) = msg.sender.call{value: availableBalance}("");
    require(success, "Transfer failed.");
  }

  function receiveRewardBalanceWithToken(uint256 tokenId) external nonReentrant {
    require(msg.sender == ownerOf(tokenId), "Only owner");
    uint256 availableReward = getRewardBalanceWithToken(tokenId);
    require(availableReward > 0, "No reward");
    rewardedBalance[tokenId] += availableReward;
    (bool success, ) = msg.sender.call{value: availableReward}("");
    require(success, "Transfer failed.");
    emit RewardReceived(msg.sender, availableReward);
  }

  function receiveRewardBalanceWithTokens(uint256[] calldata tokenIds) external nonReentrant {
    require(tokenIds.length <= balanceOf(msg.sender), "Too many tokens");
    uint256 availableReward = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if(msg.sender == ownerOf(tokenId)) {
        uint256 reward = getRewardBalanceWithToken(tokenId);
        availableReward += reward;
        rewardedBalance[tokenId] += reward;
      }
    }
    require(availableReward > 0, "No reward");
    (bool success, ) = msg.sender.call{value: availableReward}("");
    require(success, "Transfer failed.");
    emit RewardReceived(msg.sender, availableReward);
  }

  // override isApprovedForAll in ERC721A for support buyBookToken and buyMovieToken
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (owner == address(this) && operator == buyer) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  // override _baseURI in ERC721A
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}