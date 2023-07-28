// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MysticEnts is ERC721Enumerable, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;

  bool public paused = true;
  bool public revealed = false;

  string private _revealedUri;
  string private _notRevealedUri = "https://themysticents.com/nft-genesis/metadata_hidden/hidden.json";
  string private _revealedExtension = ".json";

  uint256 public price = 0.05 ether;
  uint256 public constant maxSupply = 3333;
  uint256 public constant maxMintAmount = 5;

  address private _originalOwner;

  address[4] private _creators = [
    0xb911FE9901BDBA79E6893070e4Cd979BEB0aCb47,
    0xb49826A193c50A7ac5322532CE70DEbDdE034bD2,
    0xdd24A822280b099d8eFf0bD736804714E507c8B4,
    0xf46b49dE2e3975a415FD56874682AE44Ab946d5A
  ];

  constructor() ERC721("THE MYSTIC ENTS", "TME") {
    _originalOwner = msg.sender;
  }

  //=== PUBLIC ===
  function mint(uint256 _mintAmount) public payable {
    if (msg.sender != owner()) {
      require(!paused, "Contract is paused");
      require(msg.value >= price * _mintAmount, "Value below price");
    }

    uint256 supply = totalSupply();
    require(_mintAmount > 0, "Amount needs to be above 0");
    require(_mintAmount <= maxMintAmount, "Amount is above amount limit");
    require(supply + _mintAmount <= maxSupply, "Amount above supply limit");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    if (revealed == false) {
      return _notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), _revealedExtension))
        : "";
  }

  function withdrawAll() public {
    uint256 balance = address(this).balance;
    require(balance > 0);

    for (uint256 i = 0; i < _creators.length; i++) {
      _widthdraw(_creators[i], balance.mul(10).div(100));
    }

    _widthdraw(_originalOwner, address(this).balance);
  }

  //=== OWNER ===
  function setReveal(string memory _baseUri) public onlyOwner {
    _revealedUri = _baseUri;
    revealed = true;
  }
  
  function setNotRevealedURI(string memory _newNotRevealedUri) public onlyOwner {
    _notRevealedUri = _newNotRevealedUri;
  }

  function setRevealedExtension(string memory _extension) public onlyOwner {
    _revealedExtension = _extension;
  }

  function setPause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  //=== INTERNAL ===
  function _widthdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _revealedUri;
  }
}