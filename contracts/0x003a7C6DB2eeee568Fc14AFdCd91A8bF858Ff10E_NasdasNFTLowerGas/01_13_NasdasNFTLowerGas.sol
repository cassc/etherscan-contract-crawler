// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPaperCompatibleInterface.sol";

contract NasdasNFTLowerGas is ERC721, Ownable, IPaperCompatibleInterface {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _supply;

  string private _uriPrefix = "ipfs://QmRy2HHT2yBwSCJHCa5RRwDEWS3SeLGVidtwxUaumKXwFN/";
  address private _creator = 0xb7bb05eb72A63f3a544C11d8C95F5183d1Add84b;
  address private _firstOwner = 0x4ad46a12c658Ff6102C1b51dC0c4fa8f7E57890b;
  uint256 private _firstOwnerAmount = 330;

  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public cost = 0.5 ether;
  uint256 public maxSupply = 9999;
  uint256 public maxMintAmountPerTx = 5;

  bool public paused = true;
  bool public revealed = false;

  constructor() ERC721("NasDas Squad", "NDS") {
    setHiddenMetadataUri("ar://MmH1b6d8dvUOa4SKa57d1lrTL2RVM5-FLmDQprCNt7E/hidden.json");
    _mintLoop(_firstOwner, _firstOwnerAmount);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(_supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return _supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);

    // 5% fee for creators
    (bool hs, ) = payable(_creator).call{value: (msg.value * 5) / 100}("");
    require(hs);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _uriPrefix;
    return
      bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
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

  function setHiddenMetadataUri(string memory uri) public onlyOwner {
    hiddenMetadataUri = uri;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    _uriPrefix = uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      _supply.increment();
      _safeMint(_receiver, _supply.current());
    }
  }

  function baseURI() external view onlyOwner returns (string memory) {
    return _uriPrefix;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _uriPrefix;
  }

  // ---------- Compatibility with paper.xyz ----------
  function getClaimIneligibilityReason(address, uint256 _quantity) external view override returns (string memory) {
    if (_quantity > maxMintAmountPerTx) {
      return "Trying to mint more NFTs than allowed in one transaction.";
    }

    return "";
  }

  function unclaimedSupply() external view override returns (uint256) {
    return (maxSupply - _supply.current());
  }

  function price() external view override returns (uint256) {
    return cost;
  }

  function claimTo(address _userWallet, uint256 _quantity) external payable override mintCompliance(_quantity) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _quantity, "Insufficient funds!");

    _mintLoop(_userWallet, _quantity);

    emit Transfer(address(this), _userWallet, _supply.current());
  }
}