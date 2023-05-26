// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {DefaultOperatorFilterer} from './DefaultOperatorFilterer.sol';

contract RoyalRoiers is ERC721A, DefaultOperatorFilterer, Ownable, ReentrancyGuard {

  // MINT SUPPLY AND PRICE
  uint256 public CC_PRICE = 0.0125 ether;
  uint256 public PRICE = 0.016 ether;
  uint256 public MAX_SUPPLY = 1550;
  uint256 public CC_PER_WALLET = 2;
  uint256 public MINT_PER_WALLET = 1;

  mapping(address => bool) public wlClaimed;
  mapping(address => bool) public publicClaimed;

  // SALE STATE
  enum SaleState {
    Closed,
    CoreCommunitySale,
    WlSale,
    PublicSale
  }

  SaleState private SALE_STATE = SaleState.Closed;
  
  bool public revealed = false;
  string private baseURI = "ipfs.io/ipfs/bafybeic4lm7umip2llciqk72pxemoeismskhjibi3ebjparcpojy6zuelq";
  
  bytes32 wlRoot;
  bytes32 ccRoot;

  address public constant TEAM_ADDRESS = 0xa3340BA46e1a18324f9c9101D3a0fE941131d6B6;

  constructor() ERC721A("Royal Roiers", "RR") {
    _mint(msg.sender, 1);
  }

  modifier mintCompliance(uint256 mintType, uint256 _mintAmount) {
    require(tx.origin == msg.sender,"RR: Contract mint not allowed");
    require(_mintAmount > 0, "RR: Invalid mint amount!");
    require(totalSupply() + _mintAmount <= MAX_SUPPLY, "RR: Max supply exceeded!");

    if (mintType == 1) {
      require(SALE_STATE == SaleState.CoreCommunitySale, "RR: CC Mint is not active.");
      require(_mintAmount <= CC_PER_WALLET, "RR: Mint per wallet limit");
      require(_numberMinted(_msgSender()) + _mintAmount <= CC_PER_WALLET, "RR: Max Limit per Wallet!");
    }

    if (mintType == 2) {
      require(_mintAmount <= MINT_PER_WALLET, "RR: Max Limit per Wallet !!");
      require(!wlClaimed[_msgSender()], "RR: Max Limit per Wallet!");
      require(SALE_STATE == SaleState.WlSale, "RR: WL Mint is not active.");
    }

    if(mintType == 3) {
      require(_mintAmount <= MINT_PER_WALLET, "RR: Max Limit per Wallet !!");
      require(!publicClaimed[_msgSender()], "RR: Max Limit per Wallet!");
      require(SALE_STATE == SaleState.PublicSale, "RR: Public Mint is not active");
    }
    _;
  }

  function ccMint(bytes32[] calldata proof, uint256 _mintAmount) public payable mintCompliance(1, _mintAmount) nonReentrant {
    require(MerkleProof.verifyCalldata(proof, ccRoot, keccak256(abi.encodePacked(msg.sender))), "RR: Not part of Core Community");
    require(msg.value >= CC_PRICE * _mintAmount, "RR: Send more ETh");
    _mint(msg.sender, _mintAmount);
  }

  function wlMint(bytes32[] calldata proof, uint256 _mintAmount) public payable mintCompliance(2, _mintAmount) nonReentrant {
    require(MerkleProof.verifyCalldata(proof, wlRoot, keccak256(abi.encodePacked(msg.sender))), "RR: Not Whitelisted");
    require(msg.value >= PRICE * _mintAmount, "RR: Send more ETh");
    wlClaimed[_msgSender()] = true;
    _mint(msg.sender, _mintAmount);
  }

  function publicMint(uint256 _mintAmount) public payable mintCompliance(3, _mintAmount) nonReentrant {
    require(msg.value >= PRICE * _mintAmount, "RR: Send more ETH");
    publicClaimed[_msgSender()] = true;
    _mint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _to) external onlyOwner {
    require(totalSupply() + _mintAmount <= MAX_SUPPLY, "RR: Max supply exceeded");
    _mint(_to, _mintAmount);
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

  function setCCSaleRoot(bytes32 _ccRoot) external onlyOwner {
    ccRoot = _ccRoot;
  }

  // LIMIT SETTERS
  function setCCMintLimit(uint256 _mintLimit) external onlyOwner {
    CC_PER_WALLET = _mintLimit;
  }

  function setMintPerWallet(uint256 _mintLimit) external onlyOwner {
    MINT_PER_WALLET = _mintLimit;
  }

  // PRICE FUNCTIONS
  function setPrice(uint256 _price) external onlyOwner {
    PRICE = _price;
  }

  function setCCPrice(uint256 _price) external onlyOwner {
    CC_PRICE = _price;
  }

  function getPrice() public view returns (uint256) {
    return PRICE;
  }
    
  function getCCMintPrice() public view returns (uint256) {
    return CC_PRICE;
  }

  
  // SALE STATE FUNCTIONS
  function togglePublicMintStatus() external onlyOwner {
    SALE_STATE = SaleState.PublicSale;
  }

  function toggleWlMintStatus() external onlyOwner {
    SALE_STATE = SaleState.WlSale;
  }

  function toggleCCMintStatus() external onlyOwner {
    SALE_STATE = SaleState.CoreCommunitySale;
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

  function setApprovalForAll(
      address operator,
      bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, data);
  }

  // withdraw
  function withdraw() external onlyOwner {
    payable(TEAM_ADDRESS).transfer(address(this).balance);
  }

}