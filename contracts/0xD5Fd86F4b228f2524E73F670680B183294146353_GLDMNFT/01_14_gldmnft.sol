// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Ext is IERC20 {
  function decimals() external view returns(uint8);
}

contract GLDMNFT is ERC721Enumerable, Ownable {
  using Strings for uint;

  event Deposit(address who, uint256 amount);
  event GoldMint(address to);
  event Reveal();
  event ClaimReward(address who, uint256 tokenId, uint256 amount);

  // tiers
  uint CHEST = 1;
  uint BAR = 2;
  uint SACK = 3;
  uint COIN = 4;

  // structure of representing properties of every tier
  struct Tier {
    string    name;
    uint256   rewards;
    uint      limit;
    uint      minted;
  }

  struct NFTInfo {
    uint      rarity;
    bool      rewardReceived;
  }

  // tier overviews
  mapping(uint => Tier) private tiers;
  // payment token
  IERC20Ext public tokenForPayment;
  // mint rewards
  uint256 private mintPrice;
  // map variable to generate random id
  mapping(uint => uint) private random_map;
  // inited flag
  bool private inited;
  // base uri
  string private baseURI;
  string private dummyURI;
  // NFT info
  mapping(uint256 => NFTInfo) private nfts;
  // reveal flag
  bool public revealed;
  // max supply
  uint256 private _maxSupply;
  // epoch supply
  uint256 public epochSupply;
  // round
  uint public round;
  // pause
  bool public pause;

  // initialize
  function init(string memory baseURI_, string memory dummyURI_) internal {
    CHEST = 1;
    BAR = 2;
    SACK = 3;
    COIN = 4;
    tiers[CHEST].name="Chest";
    tiers[CHEST].limit = 2;

    tiers[BAR].name="Bar";
    tiers[BAR].limit = 8;

    tiers[SACK].name="Sack";
    tiers[SACK].limit = 20;

    tiers[COIN].name="Coin";
    tiers[COIN].limit = 40;

     mintPrice = 0.44 ether; // 0.44
    epochSupply = createRandomMap(); 
    _maxSupply = epochSupply;
    inited = false;
    baseURI = baseURI_;
    dummyURI = dummyURI_;
    round = 1;
  }

  // constructor
  constructor(
    string memory name_, 
    string memory symbol_, 
    string memory baseURI_, 
    string memory dummyURI_) ERC721(name_, symbol_) {
      init(baseURI_, dummyURI_);
  }

  function createRandomMap() private returns(uint) {
    uint i;
    uint base =  0;
    for (i = 0; i < tiers[CHEST].limit; i ++)
      random_map[i] = CHEST;
    base = i;
    for (; i < base + tiers[BAR].limit; i ++)
      random_map[i] = BAR;
    base = i;
    for (; i < base + tiers[SACK].limit; i ++)
      random_map[i] = SACK;
    base = i;
    for (; i < base + tiers[COIN].limit; i ++)
      random_map[i] = COIN;
    return i;
  }

  // scale mint
  function openNewEpoch(uint[4] memory limits) public onlyOwner {
    // require(totalSupply() == _maxSupply, "[GoldMintNFT] Old round has not been finished yet!");
    for(uint i = 0; i < limits.length; i ++) {
      tiers[i+1].limit = limits[i];
      tiers[i+1].minted = 0;
    }
    epochSupply = createRandomMap();
    _maxSupply += epochSupply;
    round ++;
  }

  // set round value
  function setRound(uint round_) public onlyOwner {
    round = round_;
  }

  // set uri
  function setBaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  function setDummyURI(string memory dummyURI_) public onlyOwner {
    dummyURI = dummyURI_;
  }

  // base uri
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // set mint price
  function setMintPrice(uint256 price) public onlyOwner {
    mintPrice = price;
  }

  // set rewards amount of each tier
  function setRewards(uint id, uint256 amount) public onlyOwner {
    tiers[id].rewards = amount;
  }

  // set payment token
  function setPaymentToken(address _tokenaddr) public onlyOwner {
    tokenForPayment = IERC20Ext(_tokenaddr);
    uint8 decimals = tokenForPayment.decimals() - 2;
    uint256 unit = 10**decimals; 
    mintPrice = 44*unit; // 0.4 ether
    tiers[CHEST].rewards = 250*unit;  // 2.5 ether
    tiers[BAR].rewards = 100*unit;    // 1 ether
    tiers[SACK].rewards = 20*unit;    // 0.2 ether
    tiers[COIN].rewards = 10*unit;    // 0.1 ether
    inited = true;
  }

  // deposit token for reward
  function deposit() public onlyOwner {
    // calculate amount of deposit
    uint256 amount = 
      (tiers[CHEST].limit * tiers[CHEST].rewards) +
      (tiers[BAR].limit * tiers[BAR].rewards) +
      (tiers[SACK].limit * tiers[SACK].rewards) +
      (tiers[COIN].limit * tiers[COIN].rewards);
    require(tokenForPayment.balanceOf(msg.sender) >= amount, "Insufficient funds to deposit!");
    tokenForPayment.transferFrom(msg.sender, address(this), amount);
    
    emit Deposit(msg.sender, amount);
  }

  // generate random tier
  function getRandomizedTier() private view returns(uint) {
    uint randomNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    uint rndScaleIn = randomNumber % epochSupply;
    uint id;
    
    for(id = random_map[rndScaleIn]; id <= COIN; id ++)
    {
      Tier storage t = tiers[id];
      if (t.minted < t.limit)
        return id;
    }

    for(id = random_map[rndScaleIn]; id >= CHEST; id --)
    {
      Tier storage t = tiers[id];
      if (t.minted < t.limit)
        return id;
    }

    return 0;
  }

  // set pause to mint
  function setPause(bool flag) public onlyOwner {
    pause = flag;
  }

  // mint
  function mint() public returns(uint){
    require(inited == true, "Contract is not inited yet!");
    require(pause == false, "[GoldMintNFT] Paused to mint!");
    require(
      tokenForPayment.balanceOf(msg.sender) >= mintPrice,
      "[MINT] Insufficient funds to mint!"
    );
    uint256 tokenId = totalSupply() + 1;
    uint id = getRandomizedTier();
    require(id != 0, "All NFTs are minted. Not able to mint anymore!");
    
    // payment for mint
    tokenForPayment.transferFrom(msg.sender, address(this), mintPrice);
    // setting nft info
    nfts[tokenId].rarity = id;
    // setting tiers mint count
    tiers[id].minted += 1;
    // mint
    _mint(msg.sender, tokenId);
    emit GoldMint(msg.sender);
    return id;
  }

  // mint function 
  function mintAll() public onlyOwner {
    uint i;
    for(i = totalSupply(); i < _maxSupply; i ++)
      mint();
  }

  // claim reward
  function claimReward(uint256 tokenId) public {
    uint rarity = nfts[tokenId].rarity;
    uint256 amount = tiers[rarity].rewards;
    address tokenOwner = ownerOf(tokenId);
    require(revealed == true, "[GoldMintNFT] : Cannot get rewards under the unrevealed state!");
    require(tokenOwner == msg.sender, "GoldMintNFT: You are not the owner of this NFT!");
    require(tokenForPayment.balanceOf(address(this)) >= amount, "[GoldMintNFT] Insufficient balance for reward.");
    require(nfts[tokenId].rewardReceived == false, "[GoldMintNFT] You have already received the rewards.");
    tokenForPayment.transfer(msg.sender, amount);
    nfts[tokenId].rewardReceived = true;
    emit ClaimReward(msg.sender, tokenId, amount);
  }

  function isClaimed(uint256 tokenId) public view returns(bool) {
    return nfts[tokenId].rewardReceived;
  }

  // token uri
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    uint rarity = nfts[tokenId].rarity;
    require (rarity == CHEST ||
        rarity == BAR ||
        rarity == SACK ||
        rarity == COIN, "GoldMintNFT: Unknown rarity!");
    
    string memory uri = string(abi.encodePacked(baseURI, rarity.toString(), ".json"));
    
    if (nfts[tokenId].rewardReceived)
      return uri;

    if (!revealed)
      return dummyURI;

    return uri;
  }

  // reveal
  function reveal(bool flag) public onlyOwner {
    if (flag == true)
      require(totalSupply() == _maxSupply, "[GoldMintNFT] Not all NFTs have been minted yet!");
    revealed = flag;
  }

  // withdraw rest from this contract
  function withdraw(uint256 amount) public onlyOwner {
    require(amount <= tokenForPayment.balanceOf(address(this)), "[GodMintNFT] Cannot withraw more than balance this contract!");
    tokenForPayment.transfer(msg.sender, amount);
  }
}