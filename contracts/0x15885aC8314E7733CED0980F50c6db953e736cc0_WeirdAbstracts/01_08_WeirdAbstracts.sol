//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WeirdAbstracts is ERC721AQueryable, Ownable {
  using Strings for uint256;

  uint256 public maxSupply = 3333;
  uint256 public freeMinted;
  uint256 public maxFree = 999;
  uint256 public cost = 0.006 ether;

  string public baseURI;
  bool public isPaused = true;

  constructor(string memory _newBaseURI) ERC721A("WeirdAbstracts", "WA") {
    baseURI = _newBaseURI;
    _mint(msg.sender, 1);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");
    require(tx.origin == msg.sender, "The caller is another contract");

    require(
      _numberMinted(msg.sender) + _mintAmount <= 10,
      "Invalid mint amount!"
    );
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 requiredValue = cost * _mintAmount;
    uint256 userMinted = _numberMinted(msg.sender);
    bool isFree;

    if (userMinted == 0 && freeMinted + 1 <= maxFree) {
      requiredValue = _mintAmount <= 1 ? 0 : requiredValue - cost;
      isFree = true;
    }

    require(msg.value >= requiredValue, "Insufficient funds!");
    if (isFree) {
      freeMinted++;
    }

    _;
  }

  function mint(uint256 _mintAmount)
    public
    payable
    mintCompliance(_mintAmount)
    mintPriceCompliance(_mintAmount)
  {
    require(!isPaused, "The contract is paused!");
    _mint(msg.sender, _mintAmount);
  }

  function togglePaused() public onlyOwner {
    isPaused = !isPaused;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }

  function withdraw() external onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}