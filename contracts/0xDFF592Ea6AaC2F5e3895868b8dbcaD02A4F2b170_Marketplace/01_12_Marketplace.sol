// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/utils/Counters.sol";
import "./@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _nftsSold;
  Counters.Counter private _nftCount;
  uint256 public LISTING_FEE = 0.0001 ether;
  address payable private _marketOwner;
  mapping(uint256 => Token) private _idToToken;

  struct Token {
       address nftContract;
       uint256 tokenId;
       address payable seller;
       address payable owner;
       string tokenURI;
       string name;
       uint256 price;
       bool isListed;
   }

  event NFTListed(
    address nftContract,
    uint256 tokenId,
    address seller,
    address owner,
    uint256 price
  );
  event NFTSold(
    address nftContract,
    uint256 tokenId,
    address seller,
    address owner,
    uint256 price
  );

  constructor() {
    _marketOwner = payable(msg.sender);
  }


  // List the NFT on the marketplace
  function listNFT(address _nftContract, uint256 _tokenId, string memory _name, string memory _tokenURI) public payable nonReentrant {
    require(msg.value > 0, "Price must be at least 1 wei");
    require(msg.value == LISTING_FEE, "Not enough ether for listing fee");

    IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
    
    _nftCount.increment();

    _idToToken[_tokenId] = Token(
      _nftContract,
      _tokenId, 
      payable(msg.sender),
      payable(address(this)),
      _tokenURI, 
      _name, 
      LISTING_FEE,
      true
    );

    emit NFTListed(_nftContract, _tokenId, msg.sender, address(this), LISTING_FEE);
  }

  // Buy an NFT
  function buyNFT(address _nftContract, uint256 _tokenId) public payable nonReentrant {
    address owner = IERC721(_nftContract).ownerOf(_tokenId);
    Token storage nft = _idToToken[_tokenId];
    require(msg.value >= nft.price, "Not enough ether to cover asking price");

    address payable buyer = payable(msg.sender);
    payable(nft.seller).transfer(msg.value);
 
    IERC721(_nftContract).transferFrom(owner, msg.sender, nft.tokenId);
    IERC721(_nftContract).setApprovalForAll(msg.sender, true);

    _marketOwner.transfer(LISTING_FEE);
    nft.owner = buyer;
    nft.isListed = false;

    _nftsSold.increment();
    emit NFTSold(_nftContract, nft.tokenId, nft.seller, buyer, msg.value);
  }

  // Resell an NFT purchased from the marketplace
  function resellNFT(address _nftContract, uint256 _tokenId) public payable nonReentrant {
    address owner = IERC721(_nftContract).ownerOf(_tokenId);
    require(msg.value == LISTING_FEE, "Not enough ether for listing fee");

    // UPDATE
    IERC721(_nftContract).transferFrom(owner, address(this), _tokenId);

    Token storage nft = _idToToken[_tokenId];
    nft.seller = payable(msg.sender);
    nft.owner = payable(address(this));
    nft.isListed = true;

    _nftsSold.decrement();
    emit NFTListed(_nftContract, _tokenId, msg.sender, address(this), LISTING_FEE);
  }

  function getListingFee() public view returns (uint256) {
    return LISTING_FEE;
  }

  function getTokenForId(uint256 _tokenId) public view returns (Token memory) {
       return _idToToken[_tokenId];
   }

   function getMarketPlaceBalance() public view returns(uint256) {
       //https://docs.soliditylang.org/en/develop/units-and-global-variables.html#address-related
       return address(this).balance;
   }

   function getItemsCount() public view returns(uint256) {
       return _nftCount.current();
   }
   function getItemsSold() public view returns(uint256) {
       return _nftsSold.current();
   }
}