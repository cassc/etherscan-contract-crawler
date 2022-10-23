// SPDX-License-Identifier: MIT

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.7;

contract PixyCrocodiles is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  uint256 public cost = 0.0099 ether;
  uint256 public maxSupply = 999;
  uint256 public maxMintAmount = 2;
  uint256 public maxPerTxn = 2;
  
  bool public mintOpen = false;
  bool public revealed = false;

  constructor(
      string memory _tokenName,
      string memory _tokenSymbol,
      string memory _metadataUri,
      string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
      setUriPrefix(_metadataUri);
      setHiddenMetadataUri(_hiddenMetadataUri);
      _safeMint(0x7CAEFF36d13Fd2D8FfFA2b76b7630724c8C0c0e1, 1);
  }
 
  modifier mintCompliance(uint256 _mintAmount) {
    require(mintOpen, "The contract is not open for minting!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply minted.");
    require(_mintAmount > 0 && _mintAmount <= maxPerTxn, "Mint amount exceeds per transaction limit.");
    require(tx.origin == msg.sender, "Calling from another contract is not allowed.");
    require(
      _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "Invalid mint amount or minted max amount!"
    );
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
  
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMintState(bool _state) public onlyOwner {
    mintOpen = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 contractBalance = address(this).balance;
    (bool hs, ) = payable(owner()).call{
        value: (contractBalance * 34) / 100
    }("");
    (bool os, ) = payable(0x4b28B3367EAabe1AEeDAe62CCBe13689b2eb8F8c).call{
        value: (contractBalance * 33) / 100
    }("");
    (bool gs, ) = payable(0xa025B705a7811D68c0a92D94bbFfBC79f9c9BDc6).call{
        value: (contractBalance * 33) / 100
    }("");
     require(hs && os && gs, "Withdraw failed");
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}