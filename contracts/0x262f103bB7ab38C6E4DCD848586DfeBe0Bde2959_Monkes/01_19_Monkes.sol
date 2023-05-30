// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Banan.sol";
import "./BabyMonkes.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Monkes is ERC721Enumerable, Ownable, ReentrancyGuard {
  string public baseTokenURI;

  uint256 private breedPrice = 600;
  uint256 private _price = 0.06 ether;
  uint256 private _reserved = 50;

  bool public paused = true;
  bool public publicMintPaused = true;

  mapping(address => bool) private whitelist;
  mapping(address => uint256) private walletCount;

  Banan private bananContract;
  BabyMonkes private babyMonkesContract;

  modifier monkeOwner(uint256 _monkeId) {
    require(ownerOf(_monkeId) == msg.sender, "Monke does not belong to sender");
    _;
  }

  constructor(string memory baseURI) ERC721("Monkes", "MONKES") {
    setBaseURI(baseURI);
  }

  function mint(uint256 num) external payable nonReentrant {
    uint256 supply = totalSupply();

    require(!paused, "Minting paused");

    if (publicMintPaused) {
      require(whitelist[msg.sender], "Address is not whitelisted");
    }

    require(num > 0, "Minimum minting amount is 1");
    require(supply + num <= 3333 - _reserved, "Exceeds maximum supply");
    require(
      walletCount[msg.sender] + num < 3,
      "Max mint per account is 2 monkes"
    );
    require(msg.value >= _price * num, "Ether sent is not correct");

    for (uint256 i = 1; i <= num; i++) {
      _safeMint(msg.sender, supply + i);
    }

    walletCount[msg.sender] += num;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function breed(uint256 _parent1, uint256 _parent2)
    external
    monkeOwner(_parent1)
    monkeOwner(_parent2)
  {
    require(_parent1 != _parent2, "Parents must be different");

    bananContract.burn(msg.sender, breedPrice);
    babyMonkesContract.mint(msg.sender);
  }

  function walletOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(owner, i);
    }

    return tokensId;
  }

  function whitelistAddresses(address[] memory _addresses) public onlyOwner {
    for (uint256 i; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = true;
    }
  }

  function giveAway(address _to, uint256 _amount) external onlyOwner {
    require(_amount <= _reserved, "Exceeds reserved supply");

    uint256 supply = totalSupply();

    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(_to, supply + i);
    }

    _reserved -= _amount;
  }

  function pause(bool state) public onlyOwner {
    paused = state;
  }

  function publicMintPause(bool state) public onlyOwner {
    publicMintPaused = state;
  }

  function setBabyMonkesContract(address _babyMonkesAddress) public onlyOwner {
    babyMonkesContract = BabyMonkes(_babyMonkesAddress);
  }

  function setBananContract(address _bananAddress) public onlyOwner {
    bananContract = Banan(_bananAddress);
  }

  function setBreedPrice(uint256 _newPrice) public onlyOwner {
    breedPrice = _newPrice;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    if (address(bananContract) != address(0)) {
      bananContract.updateTokens(from, to);
    }

    ERC721.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override {
    if (address(bananContract) != address(0)) {
      bananContract.updateTokens(from, to);
    }

    ERC721.safeTransferFrom(from, to, tokenId, data);
  }

  function withdraw() public onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    string memory _tokenURI = super.tokenURI(tokenId);

    return
      bytes(_tokenURI).length > 0
        ? string(abi.encodePacked(_tokenURI, ".json"))
        : "";
  }
}