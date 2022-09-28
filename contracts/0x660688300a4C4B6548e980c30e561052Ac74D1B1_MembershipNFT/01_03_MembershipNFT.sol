// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/SimpleERC721.sol";

contract MembershipNFT is SimpleERC721 {
  struct Tier {
    string name;
    uint256 ticker;
    uint256 salePrice;
  }

  uint256 constant TIER_SPACE = 1_000_000;

  bool public initialized;

  mapping(address => bool) public agents;
  string public baseURI;
  Tier[3] public tiers;
  uint256 public MAX_SUPPLY;

  function initialize(
    string calldata _name,
    string calldata _symbol,
    string calldata _baseURI,
    string[] calldata _tiers,
    uint256[] calldata supplies
  ) external onlyOwner {
    require(!initialized);
    initialized = true;

    name = _name;
    symbol = _symbol;
    baseURI = _baseURI;

    tiers[0].name = _tiers[0];
    tiers[1].name = _tiers[1];
    tiers[2].name = _tiers[2];

    MAX_SUPPLY = (supplies[2] << 128) | (supplies[1] << 64) | supplies[0];

    agents[msg.sender] = true;
  }

  function transferOwnership(address newOwner) public override {
    delete agents[admin];
    SimpleERC721.transferOwnership(newOwner);
    agents[admin] = true;
  }

  function setAgents(address[] calldata _agents, bool isAgent) external onlyOwner {
    uint256 count = _agents.length;
    if (isAgent) {
      for (uint256 i = 0; i < count; i++) {
        agents[_agents[i]] = isAgent;
      }
    } else {
      for (uint256 i = 0; i < count; i++) {
        delete agents[_agents[i]];
      }
    }
  }

  function setSalePrices(uint256[3] calldata prices) external onlyOwner {
    tiers[0].salePrice = prices[0];
    tiers[1].salePrice = prices[1];
    tiers[2].salePrice = prices[2];
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function distribute(uint256 _tier, address[] calldata users) external {
    uint256 amount = users.length;
    require(agents[msg.sender], "Invalid role");

    Tier storage tier = tiers[_tier];
    uint256 maxSupply = uint64(MAX_SUPPLY >> (64 * _tier));
    uint256 start = tier.ticker;
    uint256 newSupply = start + amount;
    require(newSupply <= maxSupply, "Invalid amount");

    tier.ticker = newSupply;
    start = (_tier * TIER_SPACE) + start + 1;
    for (uint256 i = 0; i < amount; i++) {
      _mint(users[i], start + i);
    }
  }

  function mint(uint256 _tier, uint256 amount) external payable {
    address user = msg.sender;

    Tier storage tier = tiers[_tier];
    require(tier.salePrice > 0, "Invalid state");
    require(tier.salePrice * amount <= msg.value, "Invalid price");

    uint256 maxSupply = uint64(MAX_SUPPLY >> (64 * _tier));
    uint256 start = tier.ticker;
    uint256 newSupply = start + amount;
    require(newSupply <= maxSupply, "Invalid amount");

    tier.ticker = newSupply;
    start = (_tier * TIER_SPACE) + start + 1;
    for (uint256 i = 0; i < amount; i++) {
      _mint(user, start + i);
    }
  }

  function totalSupply() external view returns (uint256) {
    return tiers[0].ticker + tiers[1].ticker + tiers[2].ticker;
  }

  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    require(ownerOf[tokenId] != address(0));

    uint256 tier = tokenId / TIER_SPACE;
    return string(abi.encodePacked(baseURI, tiers[tier].name));
  }

  function withdraw() external onlyOwner {
    payable(admin).transfer(address(this).balance);
  }

  receive() external payable {}
}