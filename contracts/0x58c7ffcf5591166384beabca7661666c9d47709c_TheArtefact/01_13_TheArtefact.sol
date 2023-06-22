// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {DefaultOperatorFilterer} from './DefaultOperatorFilterer.sol';

contract TheArtefact is ERC721A, DefaultOperatorFilterer, Ownable, ReentrancyGuard {

  // MINT SUPPLY AND PRICE
  uint256 public WL_PRICE = 0.01 ether;
  uint256 public PUBLIC_PRICE = 0.012 ether;
  uint256 public MAX_SUPPLY = 3333;
  uint256 public MAX_PER_WALLET = 2;

  // SALE STATE
  enum SaleState {
    Closed,
    WlSale,
    PublicSale
  }
  SaleState private SALE_STATE = SaleState.Closed;
  
  bool public revealed = false;
  string private baseURI = "";
  
  bytes32 wlRoot;

  address public constant DEV_ADDRESS = 0x7204950b20020922d858163F4051E9c5A1d4a650;
  address public constant ARTIST_ADDRESS = 0xFA05bC233BB2AaC7D75905F609Eb492a406BB7Ce; 
  address public constant TEAM_ADDRESS = 0x15cbbFdeE28287352Ee41fA5f4Ee088607252007; 

  constructor() ERC721A("The Artefact", "ARTE") {
    _mint(msg.sender, 1);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "ARTE: Invalid mint amount!");
    require(_numberMinted(_msgSender()) + _mintAmount <= MAX_PER_WALLET, "ARTE: Max Limit per Wallet!");
    require(totalSupply() + _mintAmount <= MAX_SUPPLY, "ARTE: Max supply exceeded!");
    _;
  }

  modifier isSecured(uint8 mintType) {
    require(tx.origin == msg.sender,"ARTE: Contract mint not allowed");

    if (mintType == 1) {
      require(SALE_STATE == SaleState.WlSale, "ARTE: WL Mint is not active.");
    }

    if(mintType == 2) {
      require(SALE_STATE == SaleState.PublicSale, "ARTE: Public Mint is not active");
    }
    _;
  }

  function wlMint(bytes32[] memory proof, uint256 _mintAmount) public payable mintCompliance(_mintAmount) isSecured(1) nonReentrant {
    require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender))), "ARTE: Not Whitelisted");
    require(msg.value >= WL_PRICE * _mintAmount, "ARTE: Send more ETh");
    _safeMint(msg.sender, _mintAmount);
  }

  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) isSecured(2) nonReentrant {
    require(msg.value >= PUBLIC_PRICE * _mintAmount, "ARTE: Send more ETH");
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _to) external onlyOwner {
    require(totalSupply() + _mintAmount <= MAX_SUPPLY, "ARTE: Max supply exceeded");
    _mint(_to, _mintAmount);
  }

  function batchMintForAddresses(address[] calldata addresses_, uint256[] calldata amounts_) external onlyOwner {
    require(addresses_.length == amounts_.length, "ADDRESSES_AMOUNT_MISMATCH");
    unchecked {
      for (uint32 i = 0; i < addresses_.length; ++i) {
          _mint(addresses_[i], amounts_[i]);
      }
    }
   }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed) {
      return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    } else {
      return string(abi.encodePacked(baseURI));
    }
  }

  // ROOT SETTERS
  function setWLSaleRoot(bytes32 _wlRoot) external onlyOwner {
    wlRoot = _wlRoot;
  }

  // LIMIT SETTERS
  function setMintLimit(uint256 _mintLimit) external onlyOwner {
    MAX_PER_WALLET = _mintLimit;
  }

  // PRICE FUNCTIONS
  function setPublicPrice(uint256 _price) external onlyOwner {
    PUBLIC_PRICE = _price;
  }

  function setWlPrice(uint256 _price) external onlyOwner {
    WL_PRICE = _price;
  }

  function getWlMintPrice() public view returns (uint256) {
    return WL_PRICE;
  }

  function getPublicPrice() public view returns (uint256) {
    return PUBLIC_PRICE;
  }
  
  // SALE STATE FUNCTIONS
  function togglePublicMintStatus() external onlyOwner {
    SALE_STATE = SaleState.PublicSale;
  }

  function toggleWlMintStatus() external onlyOwner {
    SALE_STATE = SaleState.WlSale;
  }

  function toggleMintPaused() external onlyOwner {
    SALE_STATE = SaleState.Closed;
  }

  function getSaleState() public view returns (SaleState) {
    return SALE_STATE;
  }

  // URI
  function setBaseURI(string calldata URI) external onlyOwner {
    baseURI = URI;
  }

  function reveal(bool _revealed, string calldata _uri) external onlyOwner {
    revealed = _revealed;
    baseURI = _uri;
  }

  // withdraw
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No balance to withdraw");
    uint256 acc_a = (balance * 33) / 100;
    uint256 acc_b = (balance * 33) / 100;
    payable(ARTIST_ADDRESS).transfer(acc_a);
    payable(TEAM_ADDRESS).transfer(acc_b);
    payable(DEV_ADDRESS).transfer(address(this).balance);
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
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