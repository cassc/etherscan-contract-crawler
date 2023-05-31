// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkelProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./Strings.sol";

contract Boysvilla is ERC721A, Ownable, DefaultOperatorFilterer {

  using Strings for uint256;
  string _baseTokenURI;
  bytes32 public merkleRoot;

  bool public isActive = false;
  bool public isWhitelistSaleActive = false;

  uint256 public mintPrice = 0.0098 ether;
  uint256 public MAX_SUPPLY = 999;
  uint256 public maximumAllowedTokensPerPurchase = 2;
  uint256 public whitelistWalletLimitation = 2;
  uint256 public publicWalletLimitation = 2;

  address private wallet1 = 0x90f78b37A54eB0D12c0F6011036e373609add1B0; //main
  address private wallet2 = 0x60B0F05327b0B753fbc7d430B7D2d0fa7788d4b7; //1%
  address private wallet3 = 0x90f78b37A54eB0D12c0F6011036e373609add1B0; //6%
  address private wallet4 = 0x23A69C76F72892Dae64B71E251Bbc42dE8c7a41e; //2%
  address private wallet5 = 0x697ec3071C804d663c23DdA60a798F07Ee3B25E7; //1%

  mapping(address => uint256) private _whitelistWalletMints;
  mapping(address => uint256) private _publicWalletMints;


  constructor(string memory baseURI) ERC721A("BOYSVILLA", "BV") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  // Minting for devs to use in future giveaways and raffles and treasury

  function ownerMint(uint256 _count, address _address) external onlyOwner {
    uint256 mintIndex = totalSupply();
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");

    _safeMint(_address, _count);
  }

  function whitelistMint(bytes32[] calldata _merkleProof, uint256 _count) public payable isValidMerkleProof(_merkleProof) saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isWhitelistSaleActive, "Presale is not active");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(_count <= whitelistWalletLimitation, "Exceeds maximum allowed tokens");
    require(_whitelistWalletMints[msg.sender] + _count <= whitelistWalletLimitation, "You have already minted max");
    require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");

    _whitelistWalletMints[msg.sender] += _count;

    _safeMint(msg.sender, _count);

  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(_count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_publicWalletMints[msg.sender] + _count <= publicWalletLimitation, "You have already minted or minting more than allowed.");
    require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");

    _publicWalletMints[msg.sender] += _count;

    _safeMint(msg.sender, _count);
    
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
      require(
          MerkleProof.verify(
              merkleProof,
              merkleRoot,
              keccak256(abi.encodePacked(msg.sender))
          ),
          "Address does not exist in list"
      );
    _;
  }

  function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
    merkleRoot = _rootHash;
  }
  
  function setWhitelistSaleWalletLimitation(uint256 _maxMint) external  onlyOwner {
    whitelistWalletLimitation = _maxMint;
  }

  function setPublicSaleWalletLimitation(uint256 _count) external  onlyOwner {
    publicWalletLimitation = _count;
  }

  function setMaximumAllowedTokensPerPurchase(uint256 _count) public onlyOwner {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMaxMintSupply(uint256 _maxMintSupply) external  onlyOwner {
    MAX_SUPPLY = _maxMintSupply;
  }

  function setMintPrice(uint256 _price) public onlyOwner {
    mintPrice = _price;
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }

  function toggleWhiteslistSaleStatus() external onlyOwner {
    isWhitelistSaleActive = !isWhitelistSaleActive;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
    require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
    string memory currentBaseURI = _baseURI();
    return bytes( currentBaseURI ).length > 0 ? string( abi.encodePacked( currentBaseURI, _tokenId.toString(), ".json" ) ) : "";
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    uint256 balance1 = (balance * 90) / 100;
    uint256 balance2 = (balance * 1) / 100;
    uint256 balance3 = (balance * 6) / 100;
    uint256 balance4 = (balance * 2) / 100;
    uint256 balance5 = (balance * 1) / 100;

    payable(wallet1).transfer(balance1);
    payable(wallet2).transfer(balance2);
    payable(wallet3).transfer(balance3);
    payable(wallet4).transfer(balance4);
    payable(wallet5).transfer(balance5); 
  }

  // For compliance with opensea

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}