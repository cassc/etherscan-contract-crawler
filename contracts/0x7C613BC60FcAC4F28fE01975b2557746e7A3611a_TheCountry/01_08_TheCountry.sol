// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './ERC721B.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './ReentrancyGuard.sol';


  /*
  --Information for Mint--
    First 555 Free,
    After the First 555, One Free Mint Per Wallet & 0.002 for multiplies
    5555 Supply
  */
  
  contract TheCountry is ERC721B, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI = "";
    bool public isSaleActive = false;
    mapping(address => bool) public _freeMintClaimed;
    uint256 public constant FREE_MINTS = 555;
    uint256 public constant MAX_TOKENS = 5555;
    uint256 public constant MAX_PER_WALLET = 50;
    mapping(address => uint256) public _mintsClaimed;
    uint256 public tokenPrice = 2000000000000000;
    uint256 public constant maxPerTX = 10;

    using SafeMath for uint256;
    using Strings for uint256;
    event NFTMINTED(uint256 tokenId, address owner);

    constructor() ERC721B("TheCountry", "TC") {}
     
     function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
      }
      
      function _price() internal view virtual returns (uint256) {
        return tokenPrice;
      }
      

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
      }

      function setPrice(uint256 _newTokenPrice) public onlyOwner {
      tokenPrice = _newTokenPrice;
      }

    function activateSale() external onlyOwner {
        isSaleActive = !isSaleActive;
      }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    function Withdraw() public payable onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
    require(os);
      }

    function reserveTokens(address dev, uint256 reserveAmount)
    external
    onlyOwner
      {
        _mint(dev, reserveAmount);
      }
    function Mint(uint256 quantity) external payable {
        require(isSaleActive, "Sale not Active");
        require(
          quantity > 0 && quantity <= maxPerTX,
          "Can Mint only 10 per tx"
        );
        require(
          totalSupply().add(quantity) <= MAX_TOKENS,
          "Mint is going over Max Supply"
        );
        require(
            _mintsClaimed[msg.sender].add(quantity) <= MAX_PER_WALLET,
            "Only 50 Mints per Wallet"
        );

        if(FREE_MINTS >= totalSupply().add(quantity)){
            _mintsClaimed[msg.sender] += quantity;
            _mint(msg.sender, quantity);
        }else{
        if( _freeMintClaimed[msg.sender] != true){
        _freeMintClaimed[msg.sender] = true;
        require(
        msg.value >= tokenPrice.mul(quantity-1),
        "Free Mint Stage Over, Invalid ETH Sent, Anything after your one free mint is 0.002 eth"
        );
        _mintsClaimed[msg.sender] += quantity;
        _mint(msg.sender, quantity);
        }else{
        require(
        msg.value >= tokenPrice.mul(quantity),
         "0.002 eth per token"
        );
         _mintsClaimed[msg.sender] += quantity;
        _mint(msg.sender, quantity);
        }
        }
      }
     function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
      {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );
    
        string memory currentBaseURI = _baseURI();

        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : ""; 
            
            
      }
  }