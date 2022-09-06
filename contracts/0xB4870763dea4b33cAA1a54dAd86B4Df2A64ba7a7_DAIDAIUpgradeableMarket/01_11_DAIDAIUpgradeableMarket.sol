// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Signature.sol";

contract DAIDAIUpgradeableMarket is OwnableUpgradeable, ReentrancyGuardUpgradeable, Signature {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event AcceptListing721(address seller, address buyer, address collection, uint256 tokenId, address sellToken, uint256 price);
  event AcceptOffer721(address buyer, address seller, address collection, uint256 tokenId, address buyToken, uint256 price);
  event GlobalNonceUpdate(address indexed addr, uint256 nonce);
  event ListingNonce721Update(address indexed addr, address indexed collection, uint256 indexed tokenId, uint256 nonce);
  event OfferNonce721Update(address indexed addr, address indexed collection, uint256 indexed tokenId, uint256 nonce);

  struct Listing721 {
    address seller;
    address collection;
    uint256 tokenId;
    address sellToken;
    uint256 price;
    uint256 globalNonce;
    uint256 listingNonce;
    uint256 expiration;
  }

  struct Offer721 {
    address buyer;
    address collection;
    uint256 tokenId;
    address buyToken;
    uint256 price;
    uint256 globalNonce;
    uint256 offerNonce;
    uint256 expiration;
  }

  struct CreatorFee {
    address creator;
    uint256 fee;
  }

  uint256 constant base = 10000;

  //      user      nonce
  mapping(address=>uint256) public globalNonce;
  //      user              nft             tokenId  nonce
  mapping(address=>mapping(address=>mapping(uint256=>uint256))) public listingNonce721;
  //      user              nft             tokenId  nonce
  mapping(address=>mapping(address=>mapping(uint256=>uint256))) public offerNonce721;
  //      nft       fee
  mapping(address=>uint256) public tradingFees; //(100 = 1%, 250 = 2.5%, base = 0%, 0 = default)

  uint256 public defaultTradingFee;

  address public treasury;

  address private signer;
  
  function initialize(address treasury_) public initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    treasury = treasury_;
    defaultTradingFee = 250; // 2.5%
  }

  function setTreasuryAddress(address _treasury) public onlyOwner {
    treasury = _treasury;
  }

  function setSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function setTradingFee(address _collection, uint256 _fee) public onlyOwner {
    require(_fee <= base, "fee too large 1");
    tradingFees[_collection] = _fee;
  }

  function setDefaultTradingFee(uint256 _fee) public onlyOwner {
    require(_fee < base, "fee too large 2");
    defaultTradingFee = _fee;
  }

  function increaseGlobalNonce() public {
    globalNonce[msg.sender] += 1;
    emit GlobalNonceUpdate(msg.sender, globalNonce[msg.sender]);
  }

  function increaseListingNonce721(address _collection, uint256 _tokenId) public {
    _increaseListingNonce721(msg.sender, _collection, _tokenId);
  }

  function _increaseListingNonce721(address _addr, address _collection, uint256 _tokenId) internal {
    listingNonce721[_addr][_collection][_tokenId] += 1;
    emit ListingNonce721Update(_addr, _collection, _tokenId, listingNonce721[_addr][_collection][_tokenId]);
  }

  function increaseOfferNonce721(address _collection, uint256 _tokenId) public {
    _increaseOfferNonce721(msg.sender, _collection, _tokenId);
  }

  function _increaseOfferNonce721(address _addr, address _collection, uint256 _tokenId) internal {
    offerNonce721[_addr][_collection][_tokenId] += 1;
    emit OfferNonce721Update(_addr, _collection, _tokenId, offerNonce721[_addr][_collection][_tokenId]);
  }

  function _verifyCreatorFee(CreatorFee[] memory _fees, address _collection, uint256 _closeBefore, bytes memory _signature) internal view returns (bool) {
    require(_closeBefore > block.timestamp, "tx takes too long");
    uint len = _fees.length;
        bytes memory encoded;
        for (uint i = 0; i < len; i++) {
            encoded = bytes.concat(
                encoded,
                abi.encodePacked(_fees[i].creator, _fees[i].fee)
            );
        }
        encoded = bytes.concat(encoded, abi.encodePacked(_collection, _closeBefore));
        bytes32 message = prefixed(keccak256(encoded));
        return verifySignature(message, _signature, signer);
  }

  function tradingFeeOf(address _collection) public view returns (uint256) {
    uint256 f = tradingFees[_collection];
    if(f == 0) {
      return defaultTradingFee;
    }else if(f == base) {
      return 0;
    }else {
      return f;
    }
  }

  function _calculateFee(uint256 _amount, address _collection, CreatorFee[] memory _fees) internal view returns (uint256 trading_fee, uint256 left) {
    uint256 tfee = tradingFeeOf(_collection);
    trading_fee = tfee * _amount / base;
    uint256 cfee;
    for(uint256 i=0; i<_fees.length; i++){
      cfee += _fees[i].fee;
    }
    require(tfee + cfee < base, "fee error");
    left = _amount - trading_fee - (cfee * _amount / base);
  }

  function acceptListing721(Listing721 memory _listing,
                          bytes memory _signature1,
                          CreatorFee[] memory _fees, 
                          uint256 _closeBefore,
                          bytes memory _signature2)
                          payable public nonReentrant{
    //check condition
    require(_listing.expiration > block.timestamp, "listing expired");
    require(_listing.globalNonce == globalNonce[_listing.seller], "global nonce expired");
    require(_listing.listingNonce == listingNonce721[_listing.seller][_listing.collection][_listing.tokenId], "listing nonce expired");
    //verification
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      _listing.seller,
      _listing.collection,
      _listing.tokenId,
      _listing.sellToken,
      _listing.price,
      _listing.globalNonce,
      _listing.listingNonce,
      _listing.expiration
    )));
    require(verifySignature(message, _signature1, _listing.seller), "verification failed");
    require(_verifyCreatorFee(_fees, _listing.collection, _closeBefore, _signature2), "fee verification failed");
    //pay the price
    (uint256 trading_fee, uint256 left) = _calculateFee(_listing.price, _listing.collection, _fees);
    if(_listing.sellToken == address(0)){
      require(msg.value == _listing.price, "value error");
      payable(treasury).transfer(trading_fee);
      payable(_listing.seller).transfer(left);
      for(uint256 i=0; i<_fees.length; i++){
        payable(_fees[i].creator).transfer(_fees[i].fee * _listing.price / base);
      }
    }else{
      IERC20Upgradeable t = IERC20Upgradeable(_listing.sellToken);
      t.safeTransferFrom(msg.sender, treasury, trading_fee);
      t.safeTransferFrom(msg.sender, _listing.seller, left);
      for(uint256 i=0; i<_fees.length; i++){
        t.safeTransferFrom(msg.sender, _fees[i].creator, _fees[i].fee * _listing.price / base);
      }
    }
    //transfer NFT
    IERC721Upgradeable(_listing.collection).safeTransferFrom(_listing.seller, msg.sender, _listing.tokenId);
    //emit event
    emit AcceptListing721(_listing.seller, msg.sender, _listing.collection, _listing.tokenId, _listing.sellToken, _listing.price);
    //update nonce
    _increaseListingNonce721(_listing.seller, _listing.collection, _listing.tokenId);
  }

  function acceptOffer721(Offer721 memory _offer,
                         bytes memory _signature1,
                         CreatorFee[] memory _fees, 
                         uint256 _closeBefore,
                         bytes memory _signature2
                         ) 
                         public nonReentrant{
    //check condition
    require(_offer.expiration > block.timestamp, "listing expired");
    require(_offer.globalNonce == globalNonce[_offer.buyer], "global nonce expired");
    require(_offer.offerNonce == offerNonce721[_offer.buyer][_offer.collection][_offer.tokenId], "listing nonce expired");
    //verification
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      _offer.buyer,
      _offer.collection,
      _offer.tokenId,
      _offer.buyToken,
      _offer.price,
      _offer.globalNonce,
      _offer.offerNonce,
      _offer.expiration
    )));
    require(verifySignature(message, _signature1, _offer.buyer), "verification failed");
    require(_verifyCreatorFee(_fees, _offer.collection, _closeBefore, _signature2), "fee verification failed");
    //transfer NFT
    IERC721Upgradeable(_offer.collection).safeTransferFrom(msg.sender, _offer.buyer, _offer.tokenId);
    //receive token
    (uint256 trading_fee, uint256 left) = _calculateFee(_offer.price, _offer.collection, _fees);
    IERC20Upgradeable t = IERC20Upgradeable(_offer.buyToken);
    t.safeTransferFrom(_offer.buyer, treasury, trading_fee);
    t.safeTransferFrom(_offer.buyer, msg.sender, left);
    for(uint256 i=0; i<_fees.length; i++){
      t.safeTransferFrom(_offer.buyer, _fees[i].creator, _fees[i].fee * _offer.price / base);
    }
    //emit event
    emit AcceptOffer721(_offer.buyer, msg.sender, _offer.collection, _offer.tokenId, _offer.buyToken, _offer.price);
    //update nonce
    _increaseOfferNonce721(_offer.buyer, _offer.collection, _offer.tokenId);
  }

    function recoverFungibleTokens(address _token, address _to) payable external onlyOwner {
        uint256 amountToRecover = IERC20Upgradeable(_token).balanceOf(address(this));
        if(_token != address(0)){
          IERC20Upgradeable(_token).safeTransfer(_to, amountToRecover);
        }else{
          payable(_to).transfer(amountToRecover);
        }
    }

    function recoverNonFungibleToken(address _token, uint256 _tokenId, address _to) external onlyOwner nonReentrant {
        IERC721Upgradeable(_token).safeTransferFrom(address(this), _to, _tokenId);
    }
}