/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './interfaces/ISabreSwapOffer.sol';

contract SabreSwapBuyOffer is ISabreSwapOffer, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => uint256) public buyerBalance;

    uint256 _buyOfferCount;

    EnumerableSet.UintSet private _activeBuyOffers;

    mapping(uint256 => BuyOffer) private _buyOfferByPosition;
    mapping(uint256 => BuyOffer) private _fulfilledBuyOfferByPosition;

    mapping(address => EnumerableSet.UintSet) private _buyOffersByBuyer;

    mapping(address => uint256[]) private _fulfilledBuyOffersByBuyer;
    mapping(address => uint256[]) private _fulfilledBuyOffersBySeller;

    uint256[] private _fulfilledBuyOffers;


    function _setBuyOffer(address token, uint256 amount, uint256 pricePerToken) internal {
        if (amount == 0) revert WrongAmount();
        if (pricePerToken == 0) revert WrongPrice();

        ERC20 _token = ERC20(token);
        uint256 total = (amount * pricePerToken)/10**_token.decimals();

        if(total != msg.value) revert WrongValue();

        BuyOffer memory buy = BuyOffer(token, msg.sender, amount, pricePerToken);
        _buyOfferCount += 1;
        _activeBuyOffers.add(_buyOfferCount);
        _buyOfferByPosition[_buyOfferCount] = buy;
        _buyOffersByBuyer[msg.sender].add(_buyOfferCount);

        buyerBalance[msg.sender] += total;

        emit NewBuyOffer(msg.sender, token, amount, pricePerToken, _buyOfferCount);
    }

    function _fulfillBuyOffer(uint256 buyOfferPosition, uint256 transferFee) internal nonReentrant returns(uint256 takenFee) {
        BuyOffer memory buy = _buyOfferByPosition[buyOfferPosition];
        if(buy.buyer == address(0)) revert OfferNotFound();

        ERC20 token = ERC20(buy.token);
        uint256 total = (buy.amount * buy.ethPricePerToken)/10**token.decimals();

        buyerBalance[buy.buyer] -= total;

        takenFee = total*transferFee/(10000);
        
        token.transferFrom(msg.sender, buy.buyer, buy.amount);
        (bool sent, ) = msg.sender.call{value: total - takenFee}('');
        if (!sent) revert FailedToFulfillOffer();

        _activeBuyOffers.remove(buyOfferPosition);
        delete _buyOfferByPosition[buyOfferPosition];
        _buyOffersByBuyer[buy.buyer].remove(buyOfferPosition);
        _fulfilledBuyOffers.push(buyOfferPosition);
        _fulfilledBuyOffersByBuyer[buy.buyer].push(buyOfferPosition);
        _fulfilledBuyOffersBySeller[msg.sender].push(buyOfferPosition);
        _fulfilledBuyOfferByPosition[buyOfferPosition] = buy;

        emit BuyOfferFulfilled(msg.sender, buyOfferPosition, total - takenFee);
    }

    function cancelBuyOffer(uint256 buyOfferPosition) external nonReentrant {
        if(!_buyOffersByBuyer[msg.sender].contains(buyOfferPosition)) revert NotOfferOwnerNorFound();

        BuyOffer memory buy = _buyOfferByPosition[buyOfferPosition];
        ERC20 token = ERC20(buy.token);
        uint256 total = (buy.amount * buy.ethPricePerToken)/10**token.decimals();

        buyerBalance[msg.sender] -= total;
        (bool sent, ) = msg.sender.call{value: total}('');
        if (!sent) revert FailedToCancelOffer();

        _activeBuyOffers.remove(buyOfferPosition);
        delete _buyOfferByPosition[buyOfferPosition];
        _buyOffersByBuyer[msg.sender].remove(buyOfferPosition);

        emit CancelBuyOffer(buyOfferPosition);
    }

    function getBuyOffers(bool fulfilled) external view returns(uint256[] memory) {
        if(!fulfilled) return _activeBuyOffers.values();
        else return _fulfilledBuyOffers;
    }

    function getBuyOfferByBuyer(address buyer, bool fulfilled) external view returns(uint256[] memory) {
        if(!fulfilled) return _buyOffersByBuyer[buyer].values();
        else return _fulfilledBuyOffersByBuyer[buyer];
    }

    function getFulfilledBuyOffersBySeller(address seller) external view returns(uint256[] memory) {
        return _fulfilledBuyOffersBySeller[seller];
    }

    function getActiveBuyOffer(uint256 buyOfferPosition) external view returns(BuyOffer memory) {
        return _buyOfferByPosition[buyOfferPosition];
    }

    function getFullfilledBuyOffer(uint256 buyOfferPosition) external view returns(BuyOffer memory) {
        return _fulfilledBuyOfferByPosition[buyOfferPosition];
    }
}