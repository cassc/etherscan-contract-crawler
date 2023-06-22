// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract gmsunshines is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => uint256) public addressMintedBalance;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public price = 0.005 ether;
  uint256 public maxSupply = 2222;
  uint256 public maxMintAmountPerTx = 3;
  uint256 public addressLimitSale = 3;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = true;

  constructor() ERC721A("gmsunshines", "GMS") {
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= price * _mintAmount, "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    uint256 ownerMintedCount = addressMintedBalance[_msgSender()];
    require(ownerMintedCount + _mintAmount <= addressLimitSale, "Address exceeds maximum mint!");

    addressMintedBalance[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function switchRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

 function setAddressLimitSale(uint256 _newAddressLimitSale) public onlyOwner {
  addressLimitSale = _newAddressLimitSale;
}

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function switchPaused() public onlyOwner {
    paused = !paused;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function setSaleMintedBalance(address _addr, uint _i) public onlyOwner {
    addressMintedBalance[_addr] = _i;
  }

  function removeSaleMintedBalance(address _addr) public onlyOwner {
    delete addressMintedBalance[_addr];
  }
}