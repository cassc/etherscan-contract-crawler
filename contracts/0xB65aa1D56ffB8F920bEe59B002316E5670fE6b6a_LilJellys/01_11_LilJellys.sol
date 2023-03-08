// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract LilJellys is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;

  uint256 public jellyMax = 7000;
  uint256 maxPerTransaction = 8;
  uint256 cost = 0.003 ether;
  string public jellyUrl;
  string public uriSuffix = '.json';
  string public hiddenJellyUrl;
  bool public pauseJelly = true;
  bool public revealed = true;

  constructor() ERC721A("Lil Jellys", "LILJELLY") {
    _safeMint(msg.sender, 1);
  }

  /**
  @dev Mint a Lil Jelly!
       * 1 free per wallet
  */
  function mintJellyJelly(uint256 _mintAmount) public payable nonReentrant {

    require(!pauseJelly, "Jelly jelly jelly jelly!");
    require(_mintAmount < maxPerTransaction, "Max per transaction");

    uint256 numberMinted = _numberMinted(msg.sender);
    if (numberMinted == 0) {
        require(msg.value >= (_mintAmount - 1) * cost, "Insufficient funds!");
    } else {
        require(msg.value >= _mintAmount * cost, "Insufficient funds!");
    }

    require(totalSupply() + _mintAmount <= jellyMax, "Max supply exceeded");
    _safeMint(_msgSender(), _mintAmount);
  }

  /**
  @dev Starting token Id
  */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
  @dev Gets the token metadata
  */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenJellyUrl;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, "/", _tokenId.toString(), uriSuffix))
    : '';
  }

  /**
  @dev Sets the mintJellyJelly price
  */
  function setCost(uint256 price) public onlyOwner {
      cost = price;
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
  function sethiddenJellyUrl(string memory _hiddenJellyUrl) public onlyOwner {
    hiddenJellyUrl = _hiddenJellyUrl;
  }

  /**
  @dev Set max supply for collection
  */
  function setMaxSupply(uint256 _max) public onlyOwner {
    jellyMax = _max;
  }

  /**
  @dev Set the uri suffix
  */
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    jellyUrl = _uriPrefix;
  }

  /**
  @dev Set the uri suffix (i.e .json)
  */
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  /**
  @dev Set sale is active (pauseJelly / unstopped)
  */
  function setPaused(bool _state) public onlyOwner {
    pauseJelly = _state;
  }

  /**
  @dev Withdraw function
  */
  function withdraw() public onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return jellyUrl;
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