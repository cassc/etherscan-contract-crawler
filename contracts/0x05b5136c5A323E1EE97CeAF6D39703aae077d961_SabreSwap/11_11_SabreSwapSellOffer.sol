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

contract SabreSwapSellOffer is ISabreSwapOffer, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 private _sellOfferCount;

    EnumerableSet.UintSet private _activeSellOffers;

    mapping(uint256 => SellOffer) private _sellOfferByPosition;
    mapping(uint256 => SellOffer) private _fulfilledSellOfferByPosition;

    mapping(address => EnumerableSet.UintSet) private _sellOffersBySeller;

    uint256[] private _fulfilledSellOffers;

    mapping(address => uint256[]) private _fulfilledSellOffersBySeller;
    mapping(address => uint256[]) private _fulfilledSellOffersByBuyer;

    function _setSellOffer(
        address token,
        uint256 amount,
        uint256 ethPricePerToken
    ) internal {
        if (amount == 0) revert WrongAmount();
        if (ethPricePerToken == 0) revert WrongPrice();

        IERC20 t = IERC20(token);
        if (t.allowance(msg.sender, address(this)) < amount) revert WrongAllowance();
        if (t.balanceOf(msg.sender) < amount) revert WrongBalance();

        _sellOfferCount += 1;

        SellOffer memory sell = SellOffer(token, msg.sender, amount, ethPricePerToken);
        _sellOfferByPosition[_sellOfferCount] = sell;

        _activeSellOffers.add(_sellOfferCount);
        _sellOffersBySeller[msg.sender].add(_sellOfferCount);

        emit NewSellOffer(msg.sender, token, amount, ethPricePerToken, _sellOfferCount);
    }

    function _fulfillSellOffer(uint256 sellOfferPosition, uint256 transferFee) internal nonReentrant returns(uint256 takenFee) {
        SellOffer memory sell = _sellOfferByPosition[sellOfferPosition];
        if (sell.seller == address(0)) revert OfferNotFound();

        ERC20 token = ERC20(sell.token);

        uint256 total = (sell.amount * sell.ethPricePerToken)/10**token.decimals();
        if (total != msg.value) revert OfferWrongValue();

        takenFee = total*transferFee/(10000);

        _removeSellOffer(sellOfferPosition, sell.seller);

        _fulfilledSellOffers.push(sellOfferPosition);
        _fulfilledSellOffersBySeller[sell.seller].push(sellOfferPosition);
        _fulfilledSellOffersByBuyer[msg.sender].push(sellOfferPosition);
        _fulfilledSellOfferByPosition[sellOfferPosition] = sell;

        token.transferFrom(sell.seller, msg.sender, sell.amount);
        (bool sent, ) = sell.seller.call{value: total - takenFee}('');
        if (!sent) revert FailedToFulfillOffer();

        emit SellOfferFulfilled(msg.sender, sellOfferPosition, total - takenFee);
    }

    function cancelSellOffer(uint256 sellOfferPosition) external {
        if (!_sellOffersBySeller[msg.sender].contains(sellOfferPosition)) revert NotOfferOwnerNorFound();

        _removeSellOffer(sellOfferPosition, msg.sender);

        emit CancelSellOffer(sellOfferPosition);
    }

    function _removeSellOffer(uint256 sellOfferPosition, address seller) private {
        _activeSellOffers.remove(sellOfferPosition);
        delete _sellOfferByPosition[sellOfferPosition];
        _sellOffersBySeller[seller].remove(sellOfferPosition);
    }

    function getSellOffers(bool fulfilled) external view returns (uint256[] memory) {
        if (!fulfilled) return _activeSellOffers.values();
        else return _fulfilledSellOffers;
    }

    function getSellOfferBySeller(address seller, bool fulfilled) external view returns (uint256[] memory) {
        if (!fulfilled) return _sellOffersBySeller[seller].values();
        else return _fulfilledSellOffersBySeller[seller];
    }

    function getFulfilledSellOffersByBuyer(address buyer) external view returns (uint256[] memory) {
        return _fulfilledSellOffersByBuyer[buyer];
    }

    function getActiveSellOffer(uint256 sellOfferPosition) external view returns (SellOffer memory) {
        return _sellOfferByPosition[sellOfferPosition];
    }

    function getFullfilledSellOffer(uint256 sellOfferPosition) external view returns (SellOffer memory) {
        return _fulfilledSellOfferByPosition[sellOfferPosition];
    }
}