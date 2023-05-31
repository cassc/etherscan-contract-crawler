// SPDX-License-Identifier: MIT

// ██╗░░░██╗██╗░░░██╗███╗░░░███╗██╗
// ╚██╗░██╔╝██║░░░██║████╗░████║██║
// ░╚████╔╝░██║░░░██║██╔████╔██║██║
// ░░╚██╔╝░░██║░░░██║██║╚██╔╝██║██║
// ░░░██║░░░╚██████╔╝██║░╚═╝░██║██║
// ░░░╚═╝░░░░╚═════╝░╚═╝░░░░░╚═╝╚═╝

pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Yumi is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public _baseTokenURI;
  string public hiddenMetadataUri;

  uint256 public cost = 0.027 ether;
  uint256 public maxSupply = 5000;
  uint256 public maxMintAmountPerTx = 20;

  bool public paused = true;
  bool public revealed;

  constructor(
    string memory _hiddenMetadataUri
  ) ERC721A("Yumi", "YUMI") {
    _safeMint(msg.sender, 1);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  function mint(uint256 _mintAmount) public payable nonReentrant {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool hs, ) = payable(0xBb74a6453477Ae495ED35A4E5112DD5Fe5314F0b).call{value: address(this).balance * 25 / 100}('');
    require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  // METADATA HANDLING

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setBaseURI(string calldata baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "URI does not exist!");

      if (revealed) {
          return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
      } else {
          return hiddenMetadataUri;
      }
  }
}