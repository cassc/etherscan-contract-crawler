// SPDX-License-Identifier: MIT

/*

╔═╗┬─┐┌─┐┌─┐┌┐┌  ╔═╗┌─┐┌┐┌┌─┐┌─┐┬┌─┐  ╔╗ ┌─┐┌┐ ┬ ┬
║ ╦├┬┘├┤ ├┤ │││  ║ ╦├┤ │││├┤ └─┐│└─┐  ╠╩╗├─┤├┴┐└┬┘
╚═╝┴└─└─┘└─┘┘└┘  ╚═╝└─┘┘└┘└─┘└─┘┴└─┘  ╚═╝┴ ┴└─┘ ┴ 

*/
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkelProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./Strings.sol";

contract GreenGenesisBaby is ERC721A, Ownable, DefaultOperatorFilterer {

  // MintPrice = "Free Mint"

  using Strings for uint256;
  string _baseTokenURI;

  bool public isActive = false;

  uint256 public MAX_SUPPLY = 2000;
  uint256 public maximumAllowedTokensPerPurchase = 2;
  uint256 public publicWalletLimitation = 2;

  mapping(address => uint256) private _publicWalletMints;


  constructor(string memory baseURI) ERC721A("GREEN GENESIS BABY", "GGB") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  // Minting for devs to use in future giveaways and raffles and treasury

  function devMint(uint256 _count, address _address) external onlyOwner {
    uint256 mintIndex = totalSupply();
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");

    _safeMint(_address, _count);
  }


  function airDrop(address[] calldata recipient, uint256 _count) external onlyOwner {

    uint256 totalQuantity = recipient.length * _count;
    uint256 mintIndex = totalSupply();
    require(mintIndex + totalQuantity <= MAX_SUPPLY, "Not enough supply");
    delete totalQuantity;

    for (uint256 i = 0; i < recipient.length; ++i) {
        _safeMint(recipient[i], _count);
    }
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(_count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_publicWalletMints[msg.sender] + _count <= publicWalletLimitation, "You have already minted or minting more than allowed.");

    _publicWalletMints[msg.sender] += _count;

    _safeMint(msg.sender, _count);
    
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

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
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
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
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