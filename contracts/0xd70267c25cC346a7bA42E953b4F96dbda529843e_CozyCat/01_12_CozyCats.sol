// SPDX-License-Identifier: MIT

/*

 ██████  ██████  ███████ ██    ██      ██████  █████  ████████ ███████ 
██      ██    ██    ███   ██  ██      ██      ██   ██    ██    ██      
██      ██    ██   ███     ████       ██      ███████    ██    ███████ 
██      ██    ██  ███       ██        ██      ██   ██    ██         ██ 
 ██████  ██████  ███████    ██         ██████ ██   ██    ██    ███████ 
                                                                       
*/


pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkelProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./Strings.sol";

contract CozyCat is ERC721A, Ownable, DefaultOperatorFilterer {

  using Strings for uint256;
  string _baseTokenURI;

  bool public isActive = false;
  bool public revealed = false;

  uint256 public mintPrice = 0.0069 ether; //Price after free mint
  uint256 public MAX_SUPPLY = 4444;
  uint256 public maximumAllowedTokensPerPurchase = 4;
  uint256 public walletLimitation = 4;
  uint256 public freeMintSuppy = 1111;
  uint256 public freeMintTracker = 0;

  address private wallet1 = 0x188251a45Cf78bB2A4bf9197A97cfBE706B4dEcF;
  address private wallet2 = 0xDB5Df77973d383cdd8873Def4e89dC779aA36c85;
  address private wallet3 = 0x8C4617f8be7510c38EaceD8aaDF03824d54f79B6;
  address private wallet4 = 0xbB1ac14f866dA76c2d9636dD9b55972f17Be15E5;
  address private wallet5 = 0x97dbFeB6d2170797daABa848e1Cf57Ad976d49e1;
  address private wallet6 = 0x58fd437ca6C7D061484Af01CF762159135E2905e;

  mapping(address => uint256) private _walletMints;


  constructor(string memory baseURI) ERC721A("COZYCAT", "COZY") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  function devMint(uint256 _count, address _address) external onlyOwner {
    uint256 mintIndex = totalSupply();
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");

    _safeMint(_address, _count);
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_walletMints[msg.sender] + _count <= walletLimitation, "You have already minted or minting more than allowed.");
    if (freeMintTracker >= freeMintSuppy || _walletMints[msg.sender] >= 1) {
      require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent...");
    } else {
      if(_count > 1) {
        require(msg.value >= (mintPrice * (_count - 1)), "Insufficient ETH amount sent.");
        freeMintTracker = freeMintTracker + 1;
      } else {
        require(_walletMints[msg.sender] + _count <= 1, "You have already minted free");
        freeMintTracker = freeMintTracker + 1;
      }
    }

    _walletMints[msg.sender] += _count;
    _safeMint(msg.sender, _count);
    
  }

  function setSaleWalletLimitation(uint256 _count) external  onlyOwner {
    walletLimitation = _count;
  }

  function setMaximumAllowedTokensPerPurchase(uint256 _count) public onlyOwner {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMintPrice(uint256 _price) public onlyOwner {
    mintPrice = _price;
  }


  function setMaxMintSupply(uint256 _maxMintSupply) external  onlyOwner {
    MAX_SUPPLY = _maxMintSupply;
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }
  
  function reveal() external onlyOwner {
    revealed = !revealed;
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
    uint256 balance1 = (balance * 10) / 100;
    uint256 balance2 = (balance * 5) / 100;
    uint256 balance3 = (balance * 5) / 100;
    uint256 balance4 = (balance * 26) / 100;
    uint256 balance5 = (balance * 26) / 100;
    uint256 balance6 = (balance * 28) / 100;

    payable(wallet1).transfer(balance1);
    payable(wallet2).transfer(balance2);
    payable(wallet3).transfer(balance3);
    payable(wallet4).transfer(balance4);
    payable(wallet5).transfer(balance5);
    payable(wallet6).transfer(balance6);
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