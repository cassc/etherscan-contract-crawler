// SPDX-License-Identifier: MIT
pragma solidity >0.8.4;

// sign ref https://etherscan.io/address/0x3028b3a1133ba8dd499f37ef6b0158f8bc38f849#code
// sign vr, v, r, s
// note: v might be 0, but it should be 27 or 28

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/NftTokenHandler.sol";
import "./libs/ECDSA.sol";
import {IRoyaltyFeeManager} from "./royalty/IRoyaltyFeeManager.sol";

contract NftTrade is ReentrancyGuard, Ownable{
  using ECDSA for bytes32;
  using SafeMath for uint256;
  enum SellMethod { NOT_FOR_SELL, FIXED_PRICE, SELL_TO_HIGHEST_BIDDER, SELL_WITH_DECLINING_PRICE, ACCEPT_OFFER }

  struct Base {
    uint256 value;
  }

  struct Sale {
    address currency;
    address nftContract;
    uint256 tokenId;
    uint256 quantity;
    uint256 price;            // Declining: starting price, Fixed: exact price, Highest: starting Price.
    uint256 acceptMinPrice;   // offered price must greater or equal acceptMinPrice in all SellMethod.

    SellMethod method;

    address seller;
    address buyer; // Sale buyer address, if specified.
    uint256 nonce;
    uint256 beginTime;
    uint256 expireTime;
    uint256 maxFee;
  }
  
  struct Offer {
    address currency;
    address nftContract;
    uint256 tokenId;
    uint256 quantity;
    uint256 price;
    
    SellMethod method;

    address seller; // Offer seller address, if specified.
    address buyer;
    uint256 nonce;
    uint256 beginTime;
    uint256 expireTime;
  }

  event Dealed (
    address currency,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 quantity,
    SellMethod method,
    address seller,
    address buyer,
    uint256 sellerNonce,
    uint256 buyerNonce,
    uint256 dealedPrice,
    uint256 dealedTime,
    uint256 indexed orderId
  );

  event DealedDetail (
    uint256 price,
    uint256 acceptMinPrice,
    uint256 saleBeginTime,
    uint256 saleExpireTime,
    uint256 offerBeginTime,
    uint256 offerExpireTime,        
    uint256 maxFee,
    uint256 realRevenue,
    uint256 roalityFee,
    address roalityFeeReceiver,
    uint256 serviceFee,
    address serviceFeeReceiver,
    uint256 indexed orderId
  );

  event DealedIndexing (
    bytes32 indexed tokenIndex,
    uint256 indexed orderId
  );

  event NonceUsed(
    address user,
    uint nonce
  );


  bytes32 private constant SALE_TYPE_HASH = keccak256("Sale(address currency,address nftContract,uint256 tokenId,uint256 quantity,uint256 price,uint256 acceptMinPrice,uint8 method,address seller,address buyer,uint256 nonce,uint256 beginTime,uint256 expireTime,uint256 maxFee,bytes data)");

  bytes32 private constant OFFER_TYPE_HASH = keccak256("Offer(address currency,address nftContract,uint256 tokenId,uint256 quantity,uint256 price,uint8 method,address seller,address buyer,uint256 nonce,uint256 beginTime,uint256 expireTime,bytes data)");
  bytes32 private constant EIP712_DOMAIN_TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  string public name;
  string public version;
  uint256 private latestOrderId = 0;

  mapping (address => mapping (uint256 => bool)) private _nonceOfSigning;

  //Royalty Fee Manager, refers to the structure of https://looksrare.org/
  IRoyaltyFeeManager public royaltyFeeManager;

  //The fees charged from the protocol (250 = 2.5%, 100 = 1%)
  uint256 public adminFee = 250;

  address public adminFeeReceiver;

  constructor(string memory _name, string memory _version, address _royaltyFeeManager) {
    name = _name;
    version = _version;
    royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
    adminFeeReceiver = owner();

    uint256 id;
    assembly {
      id := chainid()
    }
  }

  function getChainID() private view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function indexToken(address nftContract, uint256 tokenId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenId));
  }

  function hashPacked(bytes32 data) private view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        _deriveDomainSeparator(),
        data
      ));
  }


  function hashSale(Sale memory sale, bytes memory data) private pure returns (bytes32) {
    return keccak256(
      abi.encode(
        SALE_TYPE_HASH,
        sale,
        keccak256(data)
      ));
  }

  function hashOffer(Offer memory offer, bytes memory data) private pure returns (bytes32) {
    return keccak256(
      abi.encode(
        OFFER_TYPE_HASH,
        offer,
        keccak256(data)
      ));
  }

  function _validateSale(Sale memory sale, bytes memory data, bytes memory saleSig) private view returns (bool) {
    return hashPacked(hashSale(sale, data)).recover(saleSig) == sale.seller;
  }

  function _validateOffer(Offer memory offer, bytes memory data, bytes memory offerSig) private view returns (bool) {
    return hashPacked(hashOffer(offer, data)).recover(offerSig) == offer.buyer;
  }

  function _dealPayments(
    uint256 price,
    uint256 roality,
    uint256 comission
  ) private pure returns (uint256[3] memory) {

    uint256 serviceFee = price
      .mul(comission).div(10000);

    uint256 sellerEarned = price
      .sub(roality)
      .sub(serviceFee);

    return [sellerEarned, roality, serviceFee];
  }

  function _payByPayable(address[3] memory receivers, uint256[3] memory payments) private {
      
    if(payments[0] > 0) payable(receivers[0]).transfer(payments[0]); // seller : sellerEarned
    if(payments[1] > 0) payable(receivers[1]).transfer(payments[1]); // roalityAccount : roalityFee
    if(payments[2] > 0) payable(receivers[2]).transfer(payments[2]); // serviceAccount : serviceFee
      
  }

  function _payByERC20(
    address erc20Contract, 
    address buyer,
    uint256 price,
    address[3] memory receivers, 
    uint256[3] memory payments) private {
    
    IERC20 money = IERC20(erc20Contract);
    require(money.balanceOf(buyer) >= price, "Buyer doesn't have enough money to pay.");
    require(money.allowance(buyer, address(this)) >= price, "Buyer allowance isn't enough.");

    money.transferFrom(buyer, address(this), price);
    if(payments[0] > 0) money.transfer(receivers[0], payments[0]); // seller : sellerEarned
    if(payments[0] > 0) money.transfer(receivers[1], payments[1]); // roalityAccount : roalityFee
    if(payments[0] > 0) money.transfer(receivers[2], payments[2]); // serviceAccount : serviceFee

  }

  // condition 1/4: direct sell (msg.sender = buyer)
  // condition 2/4: auction highest bid (msg.sender = marketplace)
  // condition 3/4: auction decling (msg.sender = buyer)
  // condition 4/4: make offer (msg.sender = seller) 
  function _deal(
    Sale memory sale, bytes memory saleSig,
    Offer memory offer, bytes memory offerSig,
    bytes memory data
  ) internal returns (uint256) {

    /* calculate hash if necessary. */
    if (offer.buyer != msg.sender) {
      require(_validateOffer(offer, data, offerSig), "Invalid offer signature");
    }
    if (sale.seller != msg.sender) {
      require(_validateSale(sale, data, saleSig), "Invalid seller signature");
    }
    // require offer not expire
    require(block.timestamp >= offer.beginTime, "Sale not available yet");
    require(block.timestamp < offer.expireTime, "Sale has expired");
    // require sale not expire
    require(block.timestamp >= sale.beginTime, "Sale not available yet");
    require(block.timestamp < sale.expireTime, "Sale has expired");

    require(sale.currency == offer.currency, "Trading currency mismatch");
    require(sale.nftContract == offer.nftContract, "Trading contract mismatch");
    require(sale.tokenId == offer.tokenId, "Trading token ID mismatch");
    require(sale.quantity == offer.quantity, "Trading quantity mismatch");
    require(sale.buyer == address(0) || sale.buyer == offer.buyer, "Trading buyer mismatch");
    require(offer.seller == address(0) || offer.seller == sale.seller, "Trading seller mismatch");

    
    require(sale.method != SellMethod.NOT_FOR_SELL, "Incorrect sale method");
    require(offer.price >= sale.acceptMinPrice, "Offered price lower than expected");

    //Nonce check
    require(_nonceOfSigning[sale.seller][sale.nonce] == false, "sale nonce has been used");
    require(_nonceOfSigning[offer.buyer][offer.nonce] == false, "offer nonce has been used");

    _nonceOfSigning[sale.seller][sale.nonce] = true;
    _nonceOfSigning[offer.buyer][offer.nonce] = true;
    
    //
    // Deal flow
    //

    ++latestOrderId;
    uint dealedPrice = priceOf(sale, offer);

    (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(sale.nftContract, sale.tokenId, dealedPrice);
    uint256[3] memory payments = _dealPayments(dealedPrice, /* roality */ royaltyFeeAmount, /* comission */ adminFee);
    address[3] memory receivers = [sale.seller, /* roality */ royaltyFeeRecipient, /* comission */ adminFeeReceiver];
    
    //check maxFee
    require((payments[1] + payments[2]) * 10000 / dealedPrice <= sale.maxFee, "maxFee error");

    // require buyer has enough eth or weth
    if(sale.currency == address(0)) {
      if(sale.method == SellMethod.FIXED_PRICE) {
        require(offer.price == msg.value, "Offered price incorrect");
        require(msg.value == dealedPrice, "Payment amount incorrect");
        _payByPayable(receivers, payments);
      } else if(sale.method == SellMethod.SELL_WITH_DECLINING_PRICE){
        require(offer.price == msg.value, "Offered price incorrect");
        require(msg.value >= dealedPrice, "Payment amount incorrect");
        _payByPayable(receivers, payments);
        // return exchanges
        if(msg.value > dealedPrice) {
          payable(msg.sender).transfer(msg.value - dealedPrice);
        }
      } else {
        revert("wrong method");
      }
    } 
    else {
      if(sale.method == SellMethod.FIXED_PRICE || sale.method == SellMethod.ACCEPT_OFFER) {
        require(offer.price == dealedPrice, "Offered price incorrect");
        _payByERC20(sale.currency, offer.buyer, dealedPrice, receivers, payments);
      } else if(sale.method == SellMethod.SELL_TO_HIGHEST_BIDDER ) {
        require(offer.price == dealedPrice, "Offered price incorrect");
        _payByERC20(sale.currency, offer.buyer, dealedPrice, receivers, payments);
      } else if(sale.method == SellMethod.SELL_WITH_DECLINING_PRICE ) {
        require(offer.price >= dealedPrice, "Offered price incorrect");
        _payByERC20(sale.currency, offer.buyer, dealedPrice, receivers, payments);
      } else {
        revert("wrong method");
      }
    }

    NftTokenHandler.transfer(sale.nftContract, sale.tokenId, sale.quantity, sale.seller, offer.buyer, data);

    endEvent(sale, offer, payments, receivers, dealedPrice);
    
    return latestOrderId;
  }

  function endEvent (Sale memory sale, Offer memory offer, uint256[3] memory payments, address[3] memory receivers, uint256 _dealedPrice) private {
     emit Dealed(
      sale.currency ,
      sale.nftContract,
      sale.tokenId,
      sale.quantity,
      sale.method,
      sale.seller,
      offer.buyer,
      sale.nonce,
      offer.nonce,
      _dealedPrice,   
      block.timestamp, 
      latestOrderId
    );
    emit DealedDetail(
      _dealedPrice,
      sale.acceptMinPrice,
      sale.beginTime,
      sale.expireTime,
      offer.beginTime,
      offer.expireTime,
      sale.maxFee,
      payments[0],      // revenue
      payments[1],      // roalityFee 
      receivers[1],  // roalityAccount, 
      payments[2],      // serviceFee
      receivers[2],  // serviceAccount
      latestOrderId
    );
    emit DealedIndexing(
      indexToken(sale.nftContract, sale.tokenId), 
      latestOrderId
    );

    emit NonceUsed(
      sale.seller,
      sale.nonce
    );

    emit NonceUsed(
      offer.buyer,
      offer.nonce
    );
  }


  function deal(
    Sale memory sale, bytes memory saleSig,
    Offer memory offer, bytes memory offerSig,
    bytes memory data
  ) public nonReentrant payable returns (uint256) {
    return _deal(
      sale, saleSig, 
      offer, offerSig,
      data
    );
  }
  function _deriveDomainSeparator() private view returns (bytes32) {
        uint256 chainId;
        chainId = getChainID();
        return keccak256(
            abi.encode(
              EIP712_DOMAIN_TYPE_HASH,
              keccak256(bytes(name)),
              keccak256(bytes(version)),
              chainId,
              address(this)
            )
        );
    }
  function priceOf(Sale memory sale, Offer memory offer) public view returns (uint256) {   
    if(sale.method == SellMethod.FIXED_PRICE) {
      return sale.price;
    }else if(sale.method == SellMethod.SELL_WITH_DECLINING_PRICE) {
      return decliningPrice(
        sale.beginTime,
        sale.expireTime,
        sale.price,
        sale.acceptMinPrice,
        block.timestamp
      );
    }else if(sale.method == SellMethod.SELL_TO_HIGHEST_BIDDER) {
      return offer.price;
    }else if(sale.method == SellMethod.ACCEPT_OFFER) {
      return offer.price;
    }else{
      revert("wrong method");
    }
  }
  function decliningPrice(
    uint256 beginTime,
    uint256 expireTime,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 targetTime
  ) public pure returns (uint256) {
      return startingPrice.sub(
        targetTime.sub(beginTime)
        .mul(startingPrice.sub(endingPrice))
        .div(expireTime.sub(beginTime)));
  }
  function validateSale (Sale memory sale, bytes memory data, bytes memory saleSig) public view returns (bool) {
    return _validateSale(sale, data, saleSig);
  }

  function validateOffer (Offer memory offer, bytes memory data, bytes memory offerSig) public view returns (bool) {
    return _validateOffer(offer, data, offerSig);
  }
  function setNonceUsed(uint256 _nonce) external {
    require(_nonceOfSigning[msg.sender][_nonce] == false, "This Nonce has been used, the order has been established, or the Offer has been cancelled");
    _nonceOfSigning[msg.sender][_nonce] = true;
    emit NonceUsed(
      msg.sender,
      _nonce
    );
  }
  function getNonceIsUsed(address _user, uint256 _nonce) public view returns (bool) {
    return _nonceOfSigning[_user][_nonce];
  }
  function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
    require(_royaltyFeeManager != address(0), "Owner: Cannot be null address");
    royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
  }
  function updateAdminFeeReceiver(address _adminFeeReceiver) external onlyOwner {
    require(_adminFeeReceiver != address(0), "Owner: Cannot be null address");
    adminFeeReceiver = _adminFeeReceiver;
  }
  function updateAdminFee(uint256 _adminFee) external onlyOwner {
    adminFee = _adminFee;
  }
}