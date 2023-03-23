// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract OrdinalFoxes is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  event TransferOrdinalToBTC(uint256 id, string ordinalWalletAddress);
  using Strings for uint256;

  uint256 public maxSupply = 5555;
  uint256 public maxFreePerWallet = 1;
  uint256 public publicMintCost = 0.003 ether;
  
  string public uriPrefix;
  string public hiddenMetadataUri;
  string public uriSuffix = '.json';

  mapping(address => bool) freeMint;
  mapping(uint16 => string) tokenIdToOrdinalWallet;
  bool public paused = true;
  bool public revealed = true;

  constructor(
    ) ERC721A(
        "OrdinalFoxes",
        "OrdinalFoxes"
    ) {
    _safeMint(msg.sender, 1);
  }

  /**
  @dev For burning
  */
  function burnToOrdinal(uint16 tokenId, string calldata ordinalWalletAddress) external {
    require(ownerOf(tokenId) == _msgSender(), "You are not the owner!");
    _burn(tokenId, true);

    // Transfer to Ordinal wallet
    tokenIdToOrdinalWallet[tokenId] = string(abi.encodePacked(_msgSender()));
    emit TransferOrdinalToBTC(tokenId, ordinalWalletAddress);
  }

  /**
  @dev For minting
  */
  function mint(uint256 _mintAmount) public payable mintCheck(_mintAmount) nonReentrant {
    require(!paused, 'Ordinal Foxes mint has not begun.');
    if(freeMint[_msgSender()]) {
      require(msg.value >= _mintAmount * publicMintCost, 'Insufficient Funds!');
    }
    else {
      require(msg.value >= (_mintAmount - 1) * publicMintCost, 'Insufficient Funds!');
      freeMint[_msgSender()] = true;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function reserve(uint8 amount) public onlyOwner {
      _safeMint(_msgSender(), amount);
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

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
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

  function setMintCost(uint256 _cost) public onlyOwner {
      publicMintCost = _cost;
  }

  modifier mintCheck(uint256 _mintAmount) {
    require(_mintAmount <= 10, "Max 10 per transaction");
    require(totalSupply() + _mintAmount <= maxSupply, 'Max Supply Exceeded!');
    _;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMaxSupply(uint256 _buffer) public onlyOwner {
    maxSupply = _buffer;
  }


  function withdraw() public onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

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