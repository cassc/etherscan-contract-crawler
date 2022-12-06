// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./libraries/EnumerableMap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ShopNEXT_NFT_Marketplace is Ownable, ReentrancyGuard {
    /**
     * @dev Emitted when change receiveFundAddress.
     */

    event ChangeReceiveFundAddress(address indexed newReceiveFundAddress);

    event ChangeMarketFee(uint256 indexed newMarketFee);

    event ChangeNFTCardAddress(address indexed newAddress);
    event ChangeTokenAddress(address indexed newAddress);

    event NftListing(uint256 indexed tokenId, uint256 price);
    event NftDelisting(uint256 indexed tokenId);
    event NftChangePrice(uint256 indexed tokenId, uint256 newPrice);
    event NftBought(
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        uint256 price,
        uint256 txFee
    );
    event NftOffered(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );
    event NftOfferCanceled(uint256 indexed tokenId, address indexed buyer);

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using SafeERC20 for IERC20;

    //mapping nftId  => price listing
    mapping(uint256 => uint256) public nftOnSales;

    //mapping from nftId to offers order ( buyer address + price)
    mapping(uint256 => EnumerableMap.AddressToUintMap) private nftOnOffers;
    mapping(address => EnumerableMap.UintToUintMap) private nftOnOffersOfUser;


    //Basis Points
    uint256 public constant BPS = 10000;

    // market fee calculate by bps
    uint256 public marketFeeInBps = 50;

    //address of nftCardAddress
    IERC721 public nftCardAddress;

    //address of sn token

    IERC20 public snAddress;

    //receive fund address
    address public receiveFun;

    /**
     * @dev Initializes the contract by setting  to marketplace.
     */
    constructor() {
        receiveFun = msg.sender;
    }

    /*
        modifier function 

    */

    
    modifier onlyNftOwner(uint256 tokenId) {
        _onlyNftOwner(tokenId);
        _;
    }
    

    /*
    *****
     external function

    *****

    */

 

    function setSNAddress(address _snAddress) external onlyOwner {
        snAddress = IERC20(_snAddress);
        emit ChangeTokenAddress(_snAddress);
    }

    function setReceiveFunAddress(address _receiveFun) external onlyOwner {
        receiveFun = _receiveFun;
        emit ChangeReceiveFundAddress(_receiveFun);
    }

    function setMarketFeeInBps(uint256 _marketFeeInBps) external onlyOwner {
        marketFeeInBps = _marketFeeInBps;
        emit ChangeMarketFee(_marketFeeInBps);
    }

    /**
     * @dev set address of  nft contract
     * only owner can this function
    
     */
    function setNFTCardAddress(address _nftCardAddress) external onlyOwner {
        nftCardAddress = IERC721(_nftCardAddress);

        emit ChangeNFTCardAddress(_nftCardAddress);
    }

    /**
     * @dev Returns total offer oder of nft
     */

    function getTotalOfferOfNft(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return nftOnOffers[tokenId].length();
    }

    function getOfferOfNftByAddress(uint256 tokenId, address user)
        external
        view
        returns (uint256)
    {
        (, uint256 currentOffer) = nftOnOffers[tokenId].tryGet(user);
        return currentOffer;
    }

    /**
     * @dev Returns offer oder at index of nftId
     */

    function getOfferOfNftByIndex(uint256 tokenId, uint256 _index)
        external
        view
        returns (address, uint256)
    {
        require(_index < nftOnOffers[tokenId].length(), "SN: out of bounds");
        return nftOnOffers[tokenId].at(_index);
    }

    function getAllOfferOfNftByTokenId(uint256 tokenId)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 len = nftOnOffers[tokenId].length();
        address[] memory ret1 = new address[](len);
        uint256[] memory ret2 = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            (ret1[i], ret2[i]) = nftOnOffers[tokenId].at(i);
        }
        return (ret1, ret2);
    }

    function getAllOfferOfUser(address user)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 len = nftOnOffersOfUser[user].length();
        uint256[] memory ret1 = new uint256[](len);
        uint256[] memory ret2 = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            (ret1[i], ret2[i]) = nftOnOffersOfUser[user].at(i);
        }
        return (ret1, ret2);
    }

    /**
     * @dev list nft for sale only owner of tokenId can this function
     * @param tokenId nft card id for sale
     * @param price  selling price
     */
    function listForSale(uint256 tokenId, uint256 price)
        external
        onlyNftOwner(tokenId)
    {
        require(price > 0, "SN: price invalid");

        //check approved nft
        require(
            IERC721(nftCardAddress).getApproved(tokenId) == address(this) ||
                IERC721(nftCardAddress).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
            "SN: require approve"
        );
        nftOnSales[tokenId] = price;

        emit NftListing(tokenId, price);
    }

    /**
      * @dev delist nft card for sale only owner of tokenId can this function
      * @param tokenId token id unList
     
     */
    function delist(uint256 tokenId) external onlyNftOwner(tokenId) {
        //check tokenId listed
        require(nftOnSales[tokenId] > 0, "SN: not listed");
        nftOnSales[tokenId] = 0;       
        emit NftDelisting(tokenId);
    }

    /**
        * @dev change price nft for sale only owner of tokenId can this function
        * @param tokenId token id changePrice
        * @param _newPrice new price
     
     */

    function changePrice(uint256 tokenId, uint256 _newPrice)
        external
        onlyNftOwner(tokenId)
    {
        //check tokenId listed
        require(nftOnSales[tokenId] > 0, "SN: not listed");

        nftOnSales[tokenId] = _newPrice;

        emit NftChangePrice(tokenId, _newPrice);
    }

    /**
     * @dev buy nft.
     *
     * @param tokenId token id 
     * @param price  price
     */

    function buy(uint256 tokenId, uint256 price) external nonReentrant {
        //get price of tokenId
        uint256 priceForList = nftOnSales[tokenId];

        require(priceForList > 0, "SN: not listed");
        require(price == priceForList, "SN: amount invalid");  
        //get address of seller
        address seller = nftCardAddress.ownerOf(tokenId);
        address buyer = msg.sender;

        require(buyer != seller, "SN: cannot buy your nft");
        
        //set price listing of tokenId
        nftOnSales[tokenId] = 0;
        _makeTransaction(tokenId, buyer, seller, price,0);

       
    }

    /**
        * @dev offer nft. 
        * 
        * @param _tokenId token id 
        * @param _price price offer
     
     */
    function offer(uint256 _tokenId, uint256 _price) external nonReentrant {
        require(_price > 0, "SN: price invalid");
        require (IERC721(nftCardAddress).ownerOf(_tokenId) != address(0));

        address buyer = msg.sender;

        //get current price offer of same buyer and heroID
        (, uint256 currentOffer) = nftOnOffers[_tokenId].tryGet(buyer);

        // check if new price is  less than current price => need refund to buyer
        bool needRefund = _price < currentOffer;

        //get value buyer must deposit if new price is greater than current price
        uint256 requiredValue = needRefund ? 0 : _price - currentOffer;

        require(
            buyer != IERC721(nftCardAddress).ownerOf(_tokenId),
            "SN: owner cannot offer"
        );
        require(_price != currentOffer, "SN: same offer");

        if (requiredValue > 0) {
            snAddress.safeTransferFrom(
                msg.sender,
                address(this),
                requiredValue
            );
        }

        //update price
        nftOnOffers[_tokenId].set(msg.sender, _price);
        nftOnOffersOfUser[msg.sender].set(_tokenId, _price);
        if (needRefund) {
            uint256 returnedValue = currentOffer - _price;
            snAddress.safeTransfer(msg.sender, returnedValue);
        }

        emit NftOffered(_tokenId, buyer, _price);
    }

    /**
        * @dev takeOffer nft. 
        * @param tokenId token id 
        * @param _buyer address buyer offer
     
     */

    function takeOffer(uint256 tokenId, address _buyer,  uint256 price)
        external
        onlyNftOwner(tokenId)
        nonReentrant
    {
        //get price buyer offer
        (, uint256 offeredValue) = nftOnOffers[tokenId].tryGet(_buyer);
        address seller = msg.sender;

        //validate data
        require(price == offeredValue, "SN: offer price invalid");
        require(offeredValue > 0, "SN: no offer found");
        require(_buyer != seller, "SN: cannot buy your own nft");

        //remove offer order
        nftOnOffers[tokenId].remove(_buyer);
        nftOnOffersOfUser[_buyer].remove(tokenId);

        _makeTransaction(tokenId, _buyer, seller, offeredValue,1);

    }

    /**
        * @dev cancelOffer nft. 
        * @param tokenId token id        
     
     */

    function cancelOffer(uint256 tokenId) external nonReentrant {
        address buyer = msg.sender;

        //get price offer of buyer for refund
        (, uint256 offerValue) = nftOnOffers[tokenId].tryGet(buyer);

        require(offerValue > 0, "SN: no offer found");

        //remove offer order
        nftOnOffers[tokenId].remove(buyer);
        nftOnOffersOfUser[msg.sender].remove(tokenId);

        //refund price value to buyer
        snAddress.safeTransfer(buyer, offerValue);

        emit NftOfferCanceled(tokenId, buyer);
    }

    /**
        * @dev execute transaction transfer nft from seller to buyer
        * send (price - marketFee) to seller
        * send marketFee to owner contract 
        * 
        * @param _tokenId token id   
        * @param _buyer  address of buyer
        * @param _seller address of seller
        * @param _price price
     
     */

    function _makeTransaction(
        uint256 _tokenId,
        address _buyer,
        address _seller,
        uint256 _price,
        uint256 _type
    ) private {
        //calculate marketFee
        uint256 marketFee = (_price * marketFeeInBps) / BPS;

        //send token to seller
        if(_type == 1){
            snAddress.safeTransfer(_seller, _price - marketFee);
            snAddress.safeTransfer(receiveFun, marketFee);
        }else{
            snAddress.safeTransferFrom(_buyer, _seller, _price - marketFee);
            snAddress.safeTransferFrom(_buyer, receiveFun, marketFee);
        }
        
        //if hero is listing => update price = 0

        if (nftOnSales[_tokenId] > 0) {
            nftOnSales[_tokenId] = 0;
           
        }
        //tranfer owner of hero from seller to buyer
        IERC721(nftCardAddress).safeTransferFrom(_seller, _buyer, _tokenId);
         emit NftBought(_tokenId, _buyer, _seller, _price,marketFee);
    }

    /**
     * @dev Throws if called by any account SNher than the owner of tokenId.
     */

    function _onlyNftOwner(uint256 tokenId) private view {
        require(
            IERC721(nftCardAddress).ownerOf(tokenId) == msg.sender,
            "SN:not nft owner"
        );
    }

}