// https://twitter.com/MushyChain

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract MushyChain is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;
  uint256 public maxSupply = 5555;
  uint256 maxPerTx = 10;
  uint256 mintPrice = 0.004 ether;
  string public uriPrefix;
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  uint256 public maxMintAmountPerWallet; 
  bool public stopped = true;
  bool public revealed = true;

  constructor(string memory uri) ERC721A("Mushy Chain", "MUSHY") {
    uriPrefix = uri;
    _safeMint(msg.sender, 1);
  }

  function mint(uint256 _mintAmount) public payable nonReentrant {
    require(!stopped, 'Mint has not started!');
    require(_mintAmount <= maxPerTx, "Max per transaction reached");

    uint256 numberMinted = _numberMinted(msg.sender);
    
    // Free Mint
    if (numberMinted > 0) {
        require(msg.value > _mintAmount * mintPrice, "Insufficient funds!");
    } else {
        require(msg.value > (_mintAmount - 1) * mintPrice, "Insufficient funds!");
    }

    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded');
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
    ? string(abi.encodePacked(currentBaseURI, "/", _tokenId.toString(), uriSuffix))
    : '';
  }

  /**
  @dev Sets the mint price
  */
  function setMintPrice(uint256 price) public onlyOwner {
      mintPrice = price;
  }

  /**
  @dev Set revealed
  */
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  /**
  @dev Unrevealed metadata url
  */
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  /**
  @dev Set max supply for collection
  */
  function setMaxSupply(uint256 _max) public onlyOwner {
    maxSupply = _max;
  }

  /**
  @dev Set the uri suffix
  */
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  /**
  @dev Set the uri suffix (i.e .json)
  */
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  /**
  @dev Set sale is active (stopped / unstopped)
  */
  function setstopped(bool _state) public onlyOwner {
    stopped = _state;
  }

  /**
  @dev Withdraw function
  */
  function withdraw() public onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  /**
  @dev OpenSea
  */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public payable
  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}