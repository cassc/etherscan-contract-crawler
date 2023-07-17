// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Shields is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint;

  string public uriPrefix = '';
  string public imgPrefix = '';
  string public uriSuffix = '.json';
  string public imgSuffix = '.png';
  string public hiddenMetadataUri;

  uint public cost;
  uint public maxSupply;

  bool public paused = true;
  bool public revealed = false;

  address public devAddress;
  address public treasuryAddress;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint _cost,
    uint _maxSupply,
    string memory _hiddenMetadataUri,
    address _devAddress,
    address _treasuryAddress
  ) ERC721A(_tokenName, _tokenSymbol) {
      setCost(_cost);
      maxSupply = _maxSupply;
      setHiddenMetadataUri(_hiddenMetadataUri);
      devAddress = _devAddress;
      treasuryAddress = _treasuryAddress;
  }

  modifier mintCompliance() {
    require(totalSupply() < maxSupply, 'exceeds max supply.');
    _;
  }

  modifier mintPriceCompliance() {
    require(msg.value >= cost, 'insufficient funds.');
    _;
  }

  function mint() external payable mintCompliance() mintPriceCompliance() {
    require(!paused, 'contract paused.');

    _safeMint(_msgSender(), 1);
  }

  function mint(address _receiver) external payable mintCompliance() mintPriceCompliance() {
    require(!paused, 'contract paused.');

    _safeMint(_receiver, 1);
  }

  function mintForAddress(address _receiver) external mintCompliance() onlyOwner {
    _safeMint(_receiver, 1);
  }

  function _startTokenId() internal view virtual override returns (uint) {
    return 1;
  }

  function tokenURI(uint _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
    require(_exists(_tokenId), 'URI query for nonexistent token.');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function imageURI(uint _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), 'URI query for nonexistent token.');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseImgURI = _baseImgURI();
    return bytes(currentBaseImgURI).length > 0
        ? string(abi.encodePacked(currentBaseImgURI, _tokenId.toString(), imgSuffix))
        : '';
  }

  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setCost(uint _cost) public onlyOwner {
    cost = _cost;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setImgPrefix(string memory _imgPrefix) external onlyOwner {
    imgPrefix = _imgPrefix;
  }

  function setImgSuffix(string memory _imgSuffix) public onlyOwner {
    imgSuffix = _imgSuffix;
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  function setTreasury(address _treasuryAddress) external onlyOwner {
    treasuryAddress = _treasuryAddress;
  }

  function withdraw() external onlyOwner nonReentrant {
    // sends 10% to dev //
    (bool hs, ) = payable(devAddress).call{value: address(this).balance * 10 / 100}('');
    require(hs);
    // sends remainder (90%) to treasury //
    (bool os, ) = payable(treasuryAddress).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _baseImgURI() internal view virtual returns (string memory) {
    return imgPrefix;
  }
}