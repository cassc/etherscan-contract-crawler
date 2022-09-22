// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTM.sol";

abstract contract NFTMPromotion is NFTM {

    mapping(string => SellPromoter) private _sellPromoters;
    struct SellPromoter {
        address payable promoter;
        uint256 promoterCoin;
        uint256 sellerCoin;
    }

    mapping(string => BuyPromoter) private _buyPromoters;
    struct BuyPromoter {
        address payable promoter;
        uint256 promoterFeeCENT;
        uint256 promoterCoin;
        uint256 buyerCoin;
    }

    function addSellPromoter (string memory promoCode, address payable promoter, uint256 promoterCoin, uint256 sellerCoin)
        public onlyOwner
    {
        require(sellerCoin > 0, "NFTM: sellerCoin can not be zero");

        _sellPromoters[promoCode] = SellPromoter({
            promoter: promoter,
            promoterCoin: promoterCoin,
            sellerCoin: sellerCoin
        });
    }

    function addBuyPromoter (string memory promoCode, address payable promoter, uint256 promoterFeeCENT, uint256 promoterCoin, uint256 buyerCoin)
        public onlyOwner
    {
        require(buyerCoin > 0, "NFTM: buyerCoin can not be zero");

        _buyPromoters[promoCode] = BuyPromoter({
            promoter: promoter,
            promoterFeeCENT: promoterFeeCENT,
            promoterCoin: promoterCoin,
            buyerCoin: buyerCoin
        });
    }

    function removeSellPromoter (string memory promoCode)
        public onlyOwner
    {
        delete _sellPromoters[promoCode];
    }

    function removeBuyPromoter (string memory promoCode)
        public onlyOwner
    {
        delete _buyPromoters[promoCode];
    }

    function validateSellPromoCode (string memory promoCode)
        public view
        returns (bool)
    {
        SellPromoter memory promotion = _sellPromoters[promoCode];
        return !(promotion.promoter == address(0) && promotion.promoterCoin == 0 && promotion.sellerCoin == 0);
    }

    function validateBuyPromoCode (string memory promoCode)
        public view
        returns (bool)
    {
        BuyPromoter memory promotion = _buyPromoters[promoCode];
        return !(promotion.promoter == address(0) && promotion.promoterFeeCENT == 0 && promotion.promoterCoin == 0 && promotion.buyerCoin == 0);
    }

    function viewSellPromoter (string memory promoCode)
        external view
        returns (string memory)
    {
        SellPromoter memory promoter = _sellPromoters[promoCode];
        string memory returnText = "";

        returnText = string.concat(returnText,'{"promoter":"0x');
        returnText = string.concat(returnText,_toAsciiString(promoter.promoter));
        returnText = string.concat(returnText,'","promoterCoin":"');
        returnText = string.concat(returnText,Strings.toString(promoter.promoterCoin));
        returnText = string.concat(returnText,'","sellerCoin":"');
        returnText = string.concat(returnText,Strings.toString(promoter.sellerCoin));
        returnText = string.concat(returnText,'"}');

        return returnText;
    }

    function viewBuyPromoter (string memory promoCode)
        external view
        returns (string memory)
    {
        BuyPromoter memory promoter = _buyPromoters[promoCode];
        string memory returnText = "";

        returnText = string.concat(returnText,'{"promoter":"0x');
        returnText = string.concat(returnText,_toAsciiString(promoter.promoter));
        returnText = string.concat(returnText,'","promoterFeeCENT":"');
        returnText = string.concat(returnText,Strings.toString(promoter.promoterFeeCENT));
        returnText = string.concat(returnText,'","promoterCoin":"');
        returnText = string.concat(returnText,Strings.toString(promoter.promoterCoin));
        returnText = string.concat(returnText,'","buyerCoin":"');
        returnText = string.concat(returnText,Strings.toString(promoter.buyerCoin));
        returnText = string.concat(returnText,'"}');

        return returnText;
    }

    function createSaleItemWithPromoCode(
        address tokenAddr,
        uint256 tokenId,
        uint256 price,
        address payable creator,
        uint256 creatorFee,
        string memory promoCode
    ) public nonReentrant {
        require(validateSellPromoCode(promoCode), "NFTM: Provided invalid promo code");

        _createSaleItemWithCreatorFee(tokenAddr, tokenId, msg.sender, price, creator, creatorFee);

        SellPromoter memory promotion = _sellPromoters[promoCode];

        if(promotion.promoterCoin > 0)
        {
            _marketCoin.issueBonusCoin(promotion.promoter, promotion.promoterCoin);
        }

        if(promotion.sellerCoin > 0)
        {
            _marketCoin.issueBonusCoin(msg.sender, promotion.sellerCoin);
        }
    }

    function buyNFTWithPromoCode(
        address tokenAddr,
        uint256 tokenId,
        string memory promoCode
    ) public payable nonReentrant onlySellingToken(tokenAddr,tokenId) onlyValidToken(tokenAddr, tokenId){
        require(validateBuyPromoCode(promoCode), "NFTM: Provided invalid promo code");

        BuyPromoter memory promotion = _buyPromoters[promoCode];

        require(promotion.promoterFeeCENT < getMarketFeeCENT(),"Promoter fee can not be more than the market fee");

        SaleItem memory item = _nftSaleItems[tokenAddr][tokenId];

        uint256 promoterFeeWEI = _centToWEI(promotion.promoterFeeCENT);
        uint256 reducedMarketFeeWEI = _centToWEI(getMarketFeeCENT()) - promoterFeeWEI;

        _executeSaleItem(tokenAddr,tokenId,item.price,item.seller,item.creator,item.creatorFee,reducedMarketFeeWEI);

        if (promoterFeeWEI != 0) {
            if (!promotion.promoter.send(promoterFeeWEI)) {
                _credits[promotion.promoter] += promoterFeeWEI;
            }
        }

        if(promotion.buyerCoin > 0)
        {
            _marketCoin.issueBonusCoin(msg.sender, promotion.buyerCoin);
        }

        if(promotion.promoterCoin > 0)
        {
            _marketCoin.issueBonusCoin(promotion.promoter, promotion.promoterCoin);
        }
    }
}