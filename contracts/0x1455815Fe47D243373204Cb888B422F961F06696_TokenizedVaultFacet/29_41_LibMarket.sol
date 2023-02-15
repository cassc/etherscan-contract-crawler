// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { MarketInfo, TokenAmount, TradingCommissions } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";
import { LibEntity } from "./LibEntity.sol";

library LibMarket {
    struct MatchingOfferResult {
        uint256 remainingBuyAmount;
        uint256 remainingSellAmount;
        uint256 buyTokenCommissionsPaid;
        uint256 sellTokenCommissionsPaid;
    }

    /// @notice order has been added
    event OrderAdded(
        uint256 indexed orderId,
        bytes32 indexed maker,
        bytes32 indexed sellToken,
        uint256 sellAmount,
        uint256 sellAmountInitial,
        bytes32 buyToken,
        uint256 buyAmount,
        uint256 buyAmountInitial,
        uint256 state
    );

    /// @notice order has been executed
    event OrderExecuted(uint256 indexed orderId, bytes32 indexed taker, bytes32 indexed sellToken, uint256 sellAmount, bytes32 buyToken, uint256 buyAmount, uint256 state);

    /// @notice order has been cancelled
    event OrderCancelled(uint256 indexed orderId, bytes32 indexed taker, bytes32 sellToken);

    function _getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.bestOfferId[_sellToken][_buyToken];
    }

    function _insertOfferIntoSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is NOT in the sorted list
        require(!_isOfferInSortedList(_offerId), "offer already in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        uint256 prevId;

        // find position of next highest offer
        uint256 top = s.bestOfferId[sellToken][buyToken];
        uint256 oldTop;

        while (top != 0 && _isOfferPricedLtOrEq(_offerId, top)) {
            oldTop = top;
            top = s.offers[top].rankPrev;
        }

        uint256 pos = oldTop;

        // insert offer at position
        if (pos != 0) {
            prevId = s.offers[pos].rankPrev;
            s.offers[pos].rankPrev = _offerId;
            s.offers[_offerId].rankNext = pos;
        }
        // else this is the new best offer, so insert at top
        else {
            prevId = s.bestOfferId[sellToken][buyToken];
            s.bestOfferId[sellToken][buyToken] = _offerId;
        }

        if (prevId != 0) {
            // requirement below is satisfied by statements above
            // require(!_isOfferPricedLtOrEq(_offerId, prevId));
            s.offers[prevId].rankNext = _offerId;
            s.offers[_offerId].rankPrev = prevId;
        }

        s.span[sellToken][buyToken]++;
    }

    function _removeOfferFromSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is in the sorted list
        require(_isOfferInSortedList(_offerId), "offer not in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        require(s.span[sellToken][buyToken] > 0, "token pair list does not exist");

        // if offer is not the highest offer
        if (_offerId != s.bestOfferId[sellToken][buyToken]) {
            uint256 nextId = s.offers[_offerId].rankNext;
            require(s.offers[nextId].rankPrev == _offerId, "sort check failed");
            s.offers[nextId].rankPrev = s.offers[_offerId].rankPrev;
        }
        // if offer is the highest offer
        else {
            s.bestOfferId[sellToken][buyToken] = s.offers[_offerId].rankPrev;
        }

        // if offer is not the lowest offer
        if (s.offers[_offerId].rankPrev != 0) {
            uint256 prevId = s.offers[_offerId].rankPrev;
            require(s.offers[prevId].rankNext == _offerId, "sort check failed");
            s.offers[prevId].rankNext = s.offers[_offerId].rankNext;
        }

        // nullify
        delete s.offers[_offerId].rankNext;
        delete s.offers[_offerId].rankPrev;

        s.span[sellToken][buyToken]--;
    }

    /**
     * @dev If the relative price of the sell token for offer1 ("low offer") is more expensive than the relative price of of the sell token for offer2 ("high offer"), then this returns true.
     *      If the sell token for offer1 is "more expensive", this means that one will need more sell token to buy the same amount of buy token when comparing relative prices of offer1 to offer2.
     */
    function _isOfferPricedLtOrEq(uint256 _lowOfferId, uint256 _highOfferId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lowSellAmount = s.offers[_lowOfferId].sellAmount;
        uint256 lowBuyAmount = s.offers[_lowOfferId].buyAmount;

        uint256 highSellAmount = s.offers[_highOfferId].sellAmount;
        uint256 highBuyAmount = s.offers[_highOfferId].buyAmount;

        return lowBuyAmount * highSellAmount >= highBuyAmount * lowSellAmount;
    }

    function _isOfferInSortedList(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        return _offerId != 0 && (s.offers[_offerId].rankNext != 0 || s.offers[_offerId].rankPrev != 0 || s.bestOfferId[sellToken][buyToken] == _offerId);
    }

    function _matchToExistingOffers(
        bytes32 _takerId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    ) internal returns (MatchingOfferResult memory result) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        result.remainingBuyAmount = _buyAmount;
        result.remainingSellAmount = _sellAmount;

        // sell: p100 buy: $100 =>  YES! buy more
        // sell: $100 buy: p100 =>  NO! DON'T buy more

        // If the buyToken is entity(p-token)   => limit both buy and sell amounts
        // If the buyToken is external          => limit only sell amount

        bool buyExternalToken = s.externalTokenSupported[LibHelpers._getAddressFromId(_buyToken)];
        while (result.remainingSellAmount != 0 && (buyExternalToken || result.remainingBuyAmount != 0)) {
            // there is at least one offer stored for token pair
            uint256 bestOfferId = s.bestOfferId[_buyToken][_sellToken];
            if (bestOfferId == 0) {
                break; // no market liquidity, bail out
            }

            uint256 makerBuyAmount = s.offers[bestOfferId].buyAmount;
            uint256 makerSellAmount = s.offers[bestOfferId].sellAmount;

            // Check if best available price on the market is better or same,
            // as the one taker is willing to pay, within error margin of ±1.
            // This ugly hack is to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has `sellAmount` and `makerSellAmount` at +1 away from
            // their "correct" values and `makerBuyAmount` and `buyAmount` at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d
            // (For detailed breakdown see https://hiddentao.com/archives/2019/09/08/maker-otc-on-chain-orderbook-deep-dive)
            if (
                makerBuyAmount * result.remainingBuyAmount >
                result.remainingSellAmount * makerSellAmount + makerBuyAmount + result.remainingBuyAmount + result.remainingSellAmount + makerSellAmount
            ) {
                break; // no matching price, bail out
            }

            // ^ The `rounding` parameter is a compromise borne of a couple days of discussion.

            // avoid stack-too-deep
            {
                // take the offer
                uint256 currentSellAmount;
                uint256 currentBuyAmount;

                if (buyExternalToken) {
                    // the amount to be sold is
                    // if the amount that wants to be purchased is less than the remaining amount, then the amount to be sold is the amount that is desired to be purchased.
                    // otherwise, it's the amount that is remaining to be sold
                    currentSellAmount = s.offers[bestOfferId].buyAmount < result.remainingSellAmount ? s.offers[bestOfferId].buyAmount : result.remainingSellAmount;
                    currentBuyAmount = (currentSellAmount * s.offers[bestOfferId].sellAmount) / s.offers[bestOfferId].buyAmount; // (a / b) * c = c * a / b  -> multiply first, avoid underflow

                    //
                    uint256 commissionsPaid = _takeOffer(bestOfferId, _takerId, currentBuyAmount, currentSellAmount, buyExternalToken);
                    result.buyTokenCommissionsPaid += commissionsPaid;
                } else {
                    currentBuyAmount = s.offers[bestOfferId].sellAmount < result.remainingBuyAmount ? s.offers[bestOfferId].sellAmount : result.remainingBuyAmount;
                    currentSellAmount = (currentBuyAmount * s.offers[bestOfferId].buyAmount) / s.offers[bestOfferId].sellAmount; // (a / b) * c = c * a / b  -> multiply first, avoid underflow
                    uint256 commissionsPaid = _takeOffer(bestOfferId, _takerId, currentBuyAmount, currentSellAmount, buyExternalToken);
                    result.sellTokenCommissionsPaid += commissionsPaid;
                }
                // calculate how much is left to buy/sell
                result.remainingSellAmount -= currentSellAmount;
                result.remainingBuyAmount = currentBuyAmount > result.remainingBuyAmount ? 0 : result.remainingBuyAmount - currentBuyAmount;
            }
        }
    }

    function _createOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        uint256 _sellAmountInitial,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _buyAmountInitial,
        uint256 _feeSchedule
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lastOfferId = ++s.lastOfferId;

        MarketInfo memory marketInfo;
        marketInfo.creator = _creator;
        marketInfo.sellToken = _sellToken;
        marketInfo.sellAmount = _sellAmount;
        marketInfo.sellAmountInitial = _sellAmountInitial;
        marketInfo.buyToken = _buyToken;
        marketInfo.buyAmount = _buyAmount;
        marketInfo.buyAmountInitial = _buyAmountInitial;
        marketInfo.feeSchedule = _feeSchedule;

        if (_buyAmount < LibConstants.DUST || _sellAmount < LibConstants.DUST) {
            marketInfo.state = LibConstants.OFFER_STATE_FULFILLED;
        } else {
            marketInfo.state = LibConstants.OFFER_STATE_ACTIVE;

            // lock tokens!
            s.lockedBalances[_creator][_sellToken] += _sellAmount;
        }

        s.offers[lastOfferId] = marketInfo;
        emit OrderAdded(lastOfferId, marketInfo.creator, _sellToken, _sellAmount, _sellAmountInitial, _buyToken, _buyAmount, _buyAmountInitial, marketInfo.state);

        return lastOfferId;
    }

    function _takeOffer(
        uint256 _offerId,
        bytes32 _takerId,
        uint256 _buyAmount,
        uint256 _sellAmount,
        bool _takeExternalToken
    ) internal returns (uint256 commissionsPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check bounds and update balances
        _checkBoundsAndUpdateBalances(_offerId, _buyAmount, _sellAmount);

        // Check fee schedule, before paying commissions
        if (s.offers[_offerId].feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD) {
            // Fees are always paid by the taker, maker pays no fees, also only in external token.
            if (_takeExternalToken) {
                // sellToken is external supported token, commissions are paid on top of _buyAmount in sellToken
                commissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, _buyAmount);
            } else {
                // sellToken is internal/participation token, commissions are paid from _sellAmount in buyToken
                commissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].buyToken, _sellAmount);
            }
        }

        s.lockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= _buyAmount;

        LibTokenizedVault._internalTransfer(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, _buyAmount);
        LibTokenizedVault._internalTransfer(_takerId, s.offers[_offerId].creator, s.offers[_offerId].buyToken, _sellAmount);

        // close offer if it has become dust
        if (s.offers[_offerId].sellAmount < LibConstants.DUST) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_FULFILLED;
            _cancelOffer(_offerId);
        }

        emit OrderExecuted(
            _offerId,
            _takerId,
            s.offers[_offerId].sellToken,
            s.offers[_offerId].sellAmount,
            s.offers[_offerId].buyToken,
            s.offers[_offerId].buyAmount,
            s.offers[_offerId].state
        );
    }

    function _checkBoundsAndUpdateBalances(
        uint256 _offerId,
        uint256 _sellAmount,
        uint256 _buyAmount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (TokenAmount memory offerSell, TokenAmount memory offerBuy) = _getOfferTokenAmounts(_offerId);

        _assertAmounts(_sellAmount, _buyAmount);

        require(_buyAmount <= offerBuy.amount, "requested buy amount too large");
        require(_sellAmount <= offerSell.amount, "calculated sell amount too large");

        // update balances
        s.offers[_offerId].sellAmount = offerSell.amount - _sellAmount;
        s.offers[_offerId].buyAmount = offerBuy.amount - _buyAmount;
    }

    function _cancelOffer(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (_isOfferInSortedList(_offerId)) {
            _removeOfferFromSortedList(_offerId);
        }

        MarketInfo memory marketInfo = s.offers[_offerId];

        // unlock the remaining sell amount back to creator
        if (marketInfo.sellAmount > 0) {
            // note nothing is transferred since tokens for sale are UN-escrowed. Just unlock!
            s.lockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= marketInfo.sellAmount;
        }

        // don't emit event stating market order is cancelled if the market order was executed and fulfilled
        if (marketInfo.state != LibConstants.OFFER_STATE_FULFILLED) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_CANCELLED;
            emit OrderCancelled(_offerId, marketInfo.creator, marketInfo.sellToken);
        }
    }

    function _assertAmounts(uint256 _sellAmount, uint256 _buyAmount) internal pure {
        require(_sellAmount <= type(uint128).max, "sell amount exceeds uint128 limit");
        require(_buyAmount <= type(uint128).max, "buy amount exceeds uint128 limit");
        require(_sellAmount > 0, "sell amount must be >0");
        require(_buyAmount > 0, "buy amount must be >0");
    }

    function _assertValidOffer(
        bytes32 _entityId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // A valid offer can only be made by an existing entity.
        require(_entityId != 0 && s.existingEntities[_entityId], "offer must be made by an existing entity");

        // note: Clarification on terminology:
        // A participation token is also called an entity token. A par token is an entity tokenized.
        // An external token is an ERC20 token. An external token can be approved to be used on the Nayms platform.
        // There can only be one participation token and one external token involved in a trade. In other words, a par token cannot be traded for another par token.
        // The platform also does not allow entities to trade external tokens (cannot trade an external token for another external token).

        bool isSellTokenAParticipationToken = s.existingEntities[_sellToken];
        bool isSellTokenASupportedExternalToken = s.externalTokenSupported[LibHelpers._getAddressFromId(_sellToken)];
        bool isBuyTokenAParticipationToken = s.existingEntities[_buyToken];
        bool isBuyTokenASupportedExternalToken = s.externalTokenSupported[LibHelpers._getAddressFromId(_buyToken)];

        _assertAmounts(_sellAmount, _buyAmount);

        require(isSellTokenAParticipationToken || isSellTokenASupportedExternalToken, "sell token must be valid");
        require(isBuyTokenAParticipationToken || isBuyTokenASupportedExternalToken, "buy token must be valid");
        require(_sellToken != _buyToken, "cannot sell and buy same token");
        require(
            (isSellTokenAParticipationToken && isBuyTokenASupportedExternalToken) || (isSellTokenASupportedExternalToken && isBuyTokenAParticipationToken),
            "must be one participation token and one external token"
        );

        // note: add restriction to not be able to sell tokens that are already for sale
        // maker must own sell amount and it must not be locked
        require(s.tokenBalances[_sellToken][_entityId] >= _sellAmount, "insufficient balance");
        require(s.tokenBalances[_sellToken][_entityId] - s.lockedBalances[_entityId][_sellToken] >= _sellAmount, "insufficient balance available, funds locked");

        // must have a valid fee schedule
        require(_feeSchedule == LibConstants.FEE_SCHEDULE_PLATFORM_ACTION || _feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD, "fee schedule invalid");
    }

    function _getOfferTokenAmounts(uint256 _offerId) internal view returns (TokenAmount memory sell_, TokenAmount memory buy_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        sell_.token = s.offers[_offerId].sellToken;
        sell_.amount = s.offers[_offerId].sellAmount;
        buy_.token = s.offers[_offerId].buyToken;
        buy_.amount = s.offers[_offerId].buyAmount;
    }

    function _executeLimitOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    )
        internal
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        )
    {
        _assertValidOffer(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);

        MatchingOfferResult memory result = _matchToExistingOffers(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount);
        buyTokenCommissionsPaid_ = result.buyTokenCommissionsPaid;
        sellTokenCommissionsPaid_ = result.sellTokenCommissionsPaid;

        offerId_ = _createOffer(_creator, _sellToken, result.remainingSellAmount, _sellAmount, _buyToken, result.remainingBuyAmount, _buyAmount, _feeSchedule);

        // if still some left
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.offers[offerId_].state == LibConstants.OFFER_STATE_ACTIVE) {
            // ensure it's in the right position in the list
            _insertOfferIntoSortedList(offerId_);
        }
    }

    function _getOffer(uint256 _offerId) internal view returns (MarketInfo memory _offerState) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId];
    }

    function _getLastOfferId() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.lastOfferId;
    }

    function _isActiveOffer(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE;
    }
}