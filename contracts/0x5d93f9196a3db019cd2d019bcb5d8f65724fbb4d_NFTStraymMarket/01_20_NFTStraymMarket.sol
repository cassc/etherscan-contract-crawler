//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import '@openzeppelin/contracts/interfaces/IERC2981.sol';

contract NFTStraymMarket is Ownable, EIP712 {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds; //total number of items ever created
  Counters.Counter private _itemsSold; //total number of items sold

  IERC20 public immutable WETH;
  address public commissionAddress;
  uint8 public commissionPercent = 0;

  uint8 constant sellOfferType = 0;
  uint8 constant buyOfferType = 1;
  uint8 constant priceTypeExact = 0;
  uint8 constant priceTypeMinMax = 1;
  uint256 constant zeroGas = 0;
  uint256 constant INITIAL_FEE = 21000;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  bytes32 constant MESSAGE_TYPEHASH = keccak256(
    "Message(address offerer,address token,uint256 tokenId,uint256 price,uint256 priceType,uint256 amount,uint256 offerType)"
  );

  constructor(
    address _WETH, address _commissionAddress, uint8 _commissionPercent
  ) EIP712("Straym Marketplace", "1") {
    WETH = IERC20(_WETH);
    commissionAddress = _commissionAddress;
    commissionPercent = _commissionPercent;
  }

  struct SellOffer {
    address seller;
    uint256 price;
    uint8 priceType;
    uint256 amount;
    bytes signature;
  }
  struct BuyOffer {
    address buyer;
    uint256 price;
    uint8 priceType;
    uint256 amount;
    bytes signature;
  }
  struct OfferToken {
    address tokenAddress;
    uint256 tokenId;
    uint256 price;
    uint256 amount;
  }
  struct Message {
    address offerer;
    address token;
    uint256 tokenId;
    uint256 price;
    uint8 priceType;
    uint256 amount;
    uint8 offerType;
  }

  //log message (when Item is sold)
  event MarketItemSelled (
    uint indexed itemId,
    address indexed tokenAddress,
    uint256 indexed tokenId,
    address  seller,
    address  owner,
    uint256 price,
    uint256 amount,
    bool sold
  );

  modifier checkSellSignature(
    SellOffer memory sellOffer,  
    OfferToken memory offerToken
  ) {
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        MESSAGE_TYPEHASH,
        sellOffer.seller,
        offerToken.tokenAddress,
        offerToken.tokenId,
        sellOffer.price,
        sellOffer.priceType,
        sellOffer.amount,
        sellOfferType      
    )));
    address signer = ECDSA.recover(digest, sellOffer.signature);
    require(signer == sellOffer.seller , 'wrong sell offer signature');
    _;
  }
  modifier checkSellerNFTPermission(
    OfferToken memory offer,
    address seller
  ) {
    require(IERC1155(offer.tokenAddress).balanceOf(seller, offer.tokenId) >= offer.amount, "Seller is not owner enough NFTs");
    require(IERC1155(offer.tokenAddress).isApprovedForAll(seller, address(this)), "Marketplace do not have permission to transfer this NFT");
    _;
  }
  modifier checkBuySignature(
    BuyOffer memory buyOffer,
    OfferToken memory offerToken
  ) {
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        MESSAGE_TYPEHASH,
        buyOffer.buyer,
        offerToken.tokenAddress,
        offerToken.tokenId,
        buyOffer.price,
        buyOffer.priceType,
        buyOffer.amount,
        buyOfferType      
    )));
    address signer = ECDSA.recover(digest, buyOffer.signature);
    require(signer == buyOffer.buyer , 'wrong buy offer signature');
    _;
  }
  modifier checkGasFee(
    uint256 gasLimit
  ) {
    require(gasleft() <= gasLimit, "Gas fee is greater than gas limit");
    _;
  }
  modifier checkBuyerWETH(
    address buyer,
    uint256 matchPrice,
    uint256 amount,
    uint256 gasLimit
  ) {
    require(IERC20(WETH).balanceOf(buyer) >= ((matchPrice * amount) + gasLimit), "Please submit the asking price in order to complete purchase");
    require(IERC20(WETH).allowance(buyer, address(this)) >= ((matchPrice * amount) + gasLimit), "Please allow the asking WETH in order to complete purchase");
    _;
  }
  modifier checkMatchWETH(
    uint256 matchPrice,
    uint256 sellPrice,
    uint256 buyPrice,
    uint8 sellPriceType,
    uint8 buyPriceType
  ) {

    require(sellPriceType == priceTypeExact || sellPriceType == priceTypeMinMax, "Sell price type not valid");
    require(buyPriceType == priceTypeExact || buyPriceType == priceTypeMinMax, "Buy price type not valid");

    if (sellPriceType == priceTypeExact) {
      require(matchPrice == sellPrice, "Match price not equal to sell price");
    }
    if (buyPriceType == priceTypeExact) {
      require(matchPrice == buyPrice, "Match price not equal to buy price");
    }
    if (sellPriceType == priceTypeMinMax) {
      require(matchPrice >= sellPrice, "Match price must be greater than min sell price");
    }
    if (buyPriceType == priceTypeMinMax) {
      require(buyPrice >= matchPrice, "Match price must be less than max buy price");
    }
    _;
  }
  modifier checkMatchAmount(
    uint256 sellAmount,
    uint256 buyAmount,
    uint256 matchAmount
  ) {
    require(matchAmount <= sellAmount && matchAmount <= buyAmount, "Match amount not valid");
    _;
  }
  modifier checkBuyerETH(
    OfferToken memory offer
  ) {
    require(msg.value >= offer.price * offer.amount, 'Insufficient funds!');
    _;
  }

  function _verifySellOffer(
    SellOffer memory sellOffer,
    OfferToken memory offerToken
  )
    private view
    checkSellSignature(sellOffer,offerToken)
    checkSellerNFTPermission(offerToken, sellOffer.seller)
    returns (bool)
  {
    return true;
  }
  function _verifyBuyOffer(
    BuyOffer memory buyOffer,
    OfferToken memory offerToken,
    uint256 gasLimit
  )
    private view
    checkBuySignature(buyOffer, offerToken)
    checkBuyerWETH(buyOffer.buyer, offerToken.price, offerToken.amount, gasLimit)
    returns (bool)
  {
    return true;
  }
  function _verifyMatchOffer(
    SellOffer memory _sellOffer,
    BuyOffer memory _buyOffer,
    OfferToken memory _offerToken
  )
    private pure
    checkMatchWETH(_offerToken.price, _sellOffer.price, _buyOffer.price, _sellOffer.priceType, _buyOffer.priceType)
    checkMatchAmount(_sellOffer.amount, _buyOffer.amount, _offerToken.amount)
    returns (bool)
  {
    return true;
  }
  function _verifyOffer(
    SellOffer memory sellOffer,
    BuyOffer memory buyOffer,
    OfferToken memory offerToken,
    uint256 gasLimit
  )
    private view
  {
    _verifySellOffer(sellOffer, offerToken);
    _verifyBuyOffer(buyOffer, offerToken, gasLimit);
    _verifyMatchOffer(sellOffer, buyOffer, offerToken);
  }

  modifier _refundGasCost(
    address offerBuyer,
    uint256 gasLimit
  )
  {
    uint remainingGasStart = gasleft();
    _;
    uint remainingGasEnd = gasleft();
    uint usedGas = remainingGasStart - remainingGasEnd;
    // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
    usedGas += INITIAL_FEE + 16000;
    // usedGas += 21000 + 9000;
    // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
    uint gasCost = usedGas * (tx.gasprice + block.basefee);
    require(gasCost <= gasLimit, "Gas fee is greater than gas limit");
    // Refund gas cost
    IERC20(WETH).transferFrom(offerBuyer, _msgSender(), gasCost);
  }

  function matchOffer(
    SellOffer memory sellOffer,
    BuyOffer memory buyOffer,
    OfferToken memory offerToken,
    uint256 gasLimit
  ) 
    public
    onlyOwner
    _refundGasCost(buyOffer.buyer, gasLimit)
  {
    _verifyOffer(sellOffer, buyOffer, offerToken, gasLimit);
    _matchOffer(sellOffer, buyOffer, offerToken);
  }
  
  function _matchOffer(
    SellOffer memory sellOffer,
    BuyOffer memory buyOffer,
    OfferToken memory offerToken
  ) 
    private
  {
    address offerSeller = sellOffer.seller;
    address offerBuyer = buyOffer.buyer;
    uint256 matchPrice = offerToken.price;
    uint256 offerAmount = offerToken.amount;
    address tokenAddress = offerToken.tokenAddress;
    uint256 tokenId = offerToken.tokenId;

    _transferWETH(offerSeller, offerBuyer, tokenAddress, tokenId, matchPrice, offerAmount);
    _transferNFTs(offerSeller, offerBuyer, tokenAddress, tokenId, matchPrice, offerAmount);
  }
  function _transferWETH(
    address offerSeller,
    address offerBuyer,
    address tokenAddress,
    uint256 tokenId,
    uint256 offerPrice,
    uint256 offerAmount
  )
    private
  {
    uint256 offerTotalPrice = offerPrice * offerAmount;
    // commision amount
    uint256 commissionAmount = offerTotalPrice * commissionPercent / 100;
    uint256 sellerReceiveAmount; 

    (address royaltiesReceiver, uint256 royaltiesAmount) = getRoyaltyInfo(tokenAddress, tokenId, offerTotalPrice);

    sellerReceiveAmount = offerTotalPrice - (commissionAmount / 2);

    if (royaltiesAmount > 0) {
      sellerReceiveAmount = sellerReceiveAmount - (royaltiesAmount / 2);
    }

    //pay the seller the amount
    IERC20(WETH).transferFrom(offerBuyer, offerSeller, sellerReceiveAmount);
    //pay commission
    IERC20(WETH).transferFrom(offerBuyer, commissionAddress, commissionAmount);
    //pay royalties
    IERC20(WETH).transferFrom(offerBuyer, royaltiesReceiver, royaltiesAmount);
  }
  function _transferETH(
    address offerSeller,
    address tokenAddress,
    uint256 tokenId,
    uint256 offerPrice,
    uint256 offerAmount
  )
    public
    payable
  {
    uint256 offerTotalPrice = offerPrice * offerAmount;
    // commision amount
    uint256 commissionAmount = offerTotalPrice * commissionPercent / 100;
    uint256 sellerReceiveAmount = offerTotalPrice - commissionAmount;

    (address royaltiesReceiver, uint256 royaltiesAmount) = getRoyaltyInfo(tokenAddress, tokenId, offerTotalPrice);
    
    if (royaltiesAmount > 0) {
      sellerReceiveAmount = sellerReceiveAmount - royaltiesAmount;
    }

    payable(offerSeller).transfer(sellerReceiveAmount);
    //pay commission
    payable(commissionAddress).transfer(commissionAmount);
    //pay royalties
    payable(royaltiesReceiver).transfer(royaltiesAmount);
  }

  function _transferNFTs(
    address offerSeller,
    address offerBuyer,
    address tokenAddress,
    uint256 tokenId,
    uint256 offerPrice,
    uint256 offerAmount
  )
    private
  {
    //transfer ownership of the nft from the contract itself to the buyer
    IERC1155(tokenAddress).safeTransferFrom(offerSeller, offerBuyer, tokenId, offerAmount, '');

    _itemIds.increment(); //add 1 to the total number of items ever created
    uint256 itemId = _itemIds.current();

    emit MarketItemSelled(
      itemId,
      tokenAddress,
      tokenId,
      offerSeller,
      offerBuyer,
      offerPrice,
      offerAmount,
      false
    );
  }

  function acceptSellOffer(
    SellOffer memory sellOffer,
    OfferToken memory offerToken
  ) 
    public 
    payable
    checkSellSignature(sellOffer,offerToken)
    checkSellerNFTPermission(offerToken, sellOffer.seller)
    checkBuyerETH(offerToken)
  {
    address offerSeller = sellOffer.seller;
    address offerBuyer = _msgSender();
    uint256 offerAmount = offerToken.amount;
    uint256 offerTokenId = offerToken.tokenId;
    address offerTokenAddress = offerToken.tokenAddress;
    uint256 offerPrice = sellOffer.price;
    
    _transferETH(offerSeller, offerTokenAddress, offerTokenId, offerPrice, offerAmount);
    //transfer ownership of the nft from the contract itself to the buyer
    IERC1155(offerTokenAddress).safeTransferFrom(offerSeller, offerBuyer, offerTokenId, offerAmount, '');

    _itemIds.increment(); //add 1 to the total number of items ever created
    uint256 itemId = _itemIds.current();

    emit MarketItemSelled(
      itemId,
      offerTokenAddress,
      offerTokenId,
      offerSeller,
      offerBuyer,
      offerPrice,
      offerAmount,
      false
    );
  }

  function acceptBuyOffer(
    BuyOffer memory buyOffer,
    OfferToken memory offerToken
  ) 
    public 
    payable
    checkSellerNFTPermission(offerToken, _msgSender())
  {
    _verifyBuyOffer(buyOffer, offerToken, zeroGas);
    address offerSeller = _msgSender();
    address offerBuyer = buyOffer.buyer;
    uint256 offerAmount = offerToken.amount;
    uint256 offerTokenId = offerToken.tokenId;
    address offerTokenAddress = offerToken.tokenAddress;
    uint256 offerPrice = buyOffer.price;

    _transferWETH(offerSeller, offerBuyer, offerTokenAddress, offerTokenId, offerPrice, offerAmount);
    //transfer ownership of the nft from the contract itself to the buyer
    IERC1155(offerTokenAddress).safeTransferFrom(offerSeller, offerBuyer, offerTokenId, offerAmount, '');

    _itemIds.increment(); //add 1 to the total number of items ever created
    uint256 itemId = _itemIds.current();

    emit MarketItemSelled(
      itemId,
      offerTokenAddress,
      offerTokenId,
      offerSeller,
      offerBuyer,
      offerPrice,
      offerAmount,
      false
    );
  }

  /// @notice Set new commission address
  function setCommissionAddress(address _commissionAddress) public onlyOwner {
    commissionAddress = _commissionAddress;
  }
  /// @notice Set new commission percent
  function setCommissionPercent(uint8 _commissionPercent) public onlyOwner {
    commissionPercent = _commissionPercent;
  }
  /// @notice Check for support royalties of token contract
  function checkRoyalties(address  _contract) 
    public
    view 
    returns (bool) 
  {
    (bool success) = IERC2981(_contract).
    supportsInterface(_INTERFACE_ID_ERC2981);
    return success;
  }
  /// @notice Get royalties info of token
  function getRoyaltyInfo(address _tokenAddress, uint256 _tokenId, uint256 _salePrice)
    public
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(_tokenAddress)
        .royaltyInfo(_tokenId, _salePrice);
    return (royaltiesReceiver, royaltiesAmount);
  }
}