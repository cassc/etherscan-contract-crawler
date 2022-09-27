// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISoccerStarNftMarket {

    struct Offer {
        uint offerId;
        // token issure
        address issuer;
        // token id
        uint tokenId;
        // buyer who make the offer
        address buyer;
        // pay method
        PayMethod payMethod;
        // the price buyer offer
        uint bid;
        // the time when the offer modified
        uint mt;
        // expiration deadline 
        uint expiration;
    }

    struct Order {
        uint orderId;
        // the contract which issue the token
        address issuer;
        uint tokenId;
        address owner;
        PayMethod payMethod;
        // the time when the offer modified
        uint mt;
        uint price;
        uint expiration;
    }

    enum PayMethod {
        PAY_BNB,
        PAY_BUSD,
        PAY_BIB
    }

    event OpenOrder(
    address sender, address issuer, uint orderId, 
    uint tokenId, PayMethod payMethod, uint price, 
    uint mt, uint expiration);

    event UpdateOrder(
    address sender, address issuer, uint orderId, 
    uint tokenId, PayMethod payMethod, uint price, 
    uint mt, uint expiration);

    event MakeDeal(
        address sender,
        address owner,
        address buyer,
        address issuer,
        uint tokenId,
        PayMethod payMethod,
        uint price,
        uint fee
    );

    event UpdateOrderPrice(address sender, uint orderId, uint oldPrice, uint newPrice);
    event UpdateOfferPrice(address sender, uint offerId, uint oldPrice, uint newPrice);

    event CloseOrder(address sender, uint orderId);
    event CancelOffer(address sender, uint offerId);

    event MakeOffer(address sender, address issuer, uint tokenId, uint offerId,
                    PayMethod payMethod, uint price, uint mt,uint expiration);
    event UpdateOffer(address sender, address issuer, uint tokenId, uint offerId,
                    PayMethod payMethod, uint price, uint mt,uint expiration);

    function setRoyaltyRatio(uint feeRatio) external;

    function setFeeRatio(uint feeRatio) external;

    function getBlockTime() external view returns(uint);

    function isOriginOwner(address issuer, uint tokenId, address owner) external view returns(bool);

    // user create a order
    function openOrder(address issuer, uint tokenId, PayMethod payMethod, uint price, uint expiration) payable external;

    // check if a token has a order to connected
    function hasOrder(address issuer,  uint tokenId) external view returns(bool);

    // return the order opened to the tokenId
    function getOrder(address issuer,  uint tokenId) external view returns(Order memory);

    // Owner close the specific order if not dealed
    function closeOrder(uint orderId) external;

    // get user orders by page
    function getUserOrdersByPage(address user, uint pageSt, uint pageSz) 
    external view returns(Order[] memory);

    // Buyer accept the price and makes a deal with the sepcific order
    function acceptOrder(uint orderId) external payable;
    
    // Owner updates order price
    function updateOrderPrice(uint orderId, uint price) external payable;

    function updateOrder(uint orderId, PayMethod payMethod, uint price, uint expiration) external payable;

    // Buyer make a offer to the specific order
    function makeOffer(address issuer, uint tokenId, PayMethod payMethod, uint price, uint expiration) external payable;

    // Owner accept the offer and make a deal
    function acceptOffer(uint offerId) external payable;

    // Buyer udpate offer bid price
    function updateOfferPrice(uint offerId, uint price) external payable;

    function updateOffer(uint offerId, PayMethod payMethod, uint price, uint expiration) external payable;

    // Buyer cancle the specific offer
    function cancelOffer(uint offerId) external;

    // Buyer cancle the offers by the specific issuer
    function cancelAllOffersByIssuer(address issuer) external;
}