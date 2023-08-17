// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";  
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol"; 
import "@openzeppelin/contracts/token/common/ERC2981.sol"; 
 
 
contract NineteenThirtyFiveApes is ERC721AQueryable, ERC2981,DefaultOperatorFilterer, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "ipfs://bafkreie5i55xc354d7knshcztrpsw5ei3xywqvliqlks75224y2kqdlrtu/"; 
  
  uint256 public mintPrice = 0.0069 ether;
  uint16 public constant MAX_SUPPLY = 2000;
  uint256 public maxPerWallet = 5;
  
  bool public paused = true;
  bool public OGpaused = true;
  bool public revealed = false;
  
  address public signer = 0xd9Ea7B04D32e3C05326fcbD43064BaC5bc80E32D;   

  constructor() ERC721A("1935 Apes", "NTFA") {
      setRoyaltyInfo(0x6433cadCB7B9fE18B2C91cf926296F7E69046a8A, 690); 
      _safeMint(msg.sender, 1); // Setup  
  } 

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(_numberMinted(_msgSender()) + _mintAmount <= maxPerWallet, "Max Limit per Wallet!");
    require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
    _;
  }

  modifier OGmintCompliance(uint256 _mintAmount,uint256 _maxMint) {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(_numberMinted(_msgSender()) + _mintAmount <= _maxMint, "Max Limit per Wallet!");
    require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= mintPrice * _mintAmount, "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    require(!paused, "The contract is paused!");

    _safeMint(_msgSender(), _mintAmount);
  }

  function OGmint(uint256 quantity,uint256 _maxMint, bytes memory proof) external payable OGmintCompliance(quantity,_maxMint) mintPriceCompliance(quantity) nonReentrant {
    require(!OGpaused, "The contract is paused!");

    bytes32 digest = keccak256(abi.encodePacked(_maxMint, msg.sender));
    bytes32 message = ECDSA.toEthSignedMessageHash(digest); 
    require(ECDSA.recover(message, proof) == signer, "CONTRACT_MINT_NOT_ALLOWED");     
    _safeMint(_msgSender(), quantity);
  }  
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  } 
 
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A,IERC721A) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    mintPrice = _cost;
  }

  function setMaxPerWallet(uint256 max) public onlyOwner {
    maxPerWallet = max;
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

  function setPaused(bool _paused, bool _OGpaused) public onlyOwner {
    paused = _paused;
    OGpaused = _OGpaused;
    // phase1(OGMint) - paused=true, Ogpaused=false / p2(Public) - paused=false, OGpaused=true
  }
  
  function setSigner(address signer_) public onlyOwner{
      signer = signer_;
  } 

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  
  // ========= OPERATOR FILTERER OVERRIDES =========

  function setApprovalForAll(address operator, bool approved) public override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  

  function approve(address operator, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }
  

  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }
  

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }
  

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public payable
  override(ERC721A,IERC721A)
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // ========= ROYALTY =========

  // IERC2981
  function setRoyaltyInfo(address receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
  }
  // ERC165
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A, IERC721A) returns(bool) { 
    return interfaceId == type(IERC721Metadata).interfaceId || interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
  } 
}