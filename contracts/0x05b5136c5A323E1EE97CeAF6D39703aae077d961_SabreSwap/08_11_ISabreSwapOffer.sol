/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface ISabreSwapOffer {

    event NewBuyOffer(address indexed buyer, address token, uint256 amount, uint256 pricePerToken, uint256 _buyOfferCount);
    event CancelBuyOffer(uint256 buyOfferPosition);
    event BuyOfferFulfilled(address indexed seller, uint256 offerPosition, uint256 price);

    event NewSellOffer(
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 pricePerToken,
        uint256 _sellOfferCount
    );
    event CancelSellOffer(uint256 offerPosition);
    event SellOfferFulfilled(address indexed buyer, uint256 offerPosition, uint256 price);

    error WrongAmount();
    error WrongPrice();
    error WrongValue();
    error NotOfferOwnerNorFound();
    error OfferNotFound();
    error FailedToFulfillOffer();
    error WrongAllowance();
    error WrongBalance();
    error OfferWrongValue();
    error FailedToCancelOffer();

    struct BuyOffer {
        address token;
        address buyer;
        uint256 amount;
        uint256 ethPricePerToken;
    }

    struct SellOffer {
        address token;
        address seller;
        uint256 amount;
        uint256 ethPricePerToken;
    }
}