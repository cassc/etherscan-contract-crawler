// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Modifiers } from "../Modifiers.sol";
import { TradingCommissions, TradingCommissionsBasisPoints, MarketInfo } from "../AppStorage.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibMarket } from "../libs/LibMarket.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibFeeRouter } from "../libs/LibFeeRouter.sol";
import { IMarketFacet } from "../interfaces/IMarketFacet.sol";

import { ReentrancyGuard } from "../../../utils/ReentrancyGuard.sol";

/**
 * @title Matching Market (inspired by MakerOTC: https://github.com/nayms/maker-otc/blob/master/contracts/matching_market.sol)
 * @notice Trade entity tokens
 * @dev This should only be called through an entity, never directly by an EOA
 */
contract MarketFacet is IMarketFacet, Modifiers, ReentrancyGuard {
    /**
     * @notice Cancel offer #`_offerId`. This will cancel the offer so that it's no longer active.
     *
     * @dev This function can be frontrun: In the scenario where a user wants to cancel an unfavorable market offer, an attacker can potentially monitor and identify
     *       that the user has called this method, determine that filling this market offer is profitable, and as a result call executeLimitOffer with a higher gas price to have
     *       their transaction filled before the user can have cancelOffer filled. The most ideal situation for the user is to not have placed the unfavorable market offer
     *       in the first place since an attacker can always monitor our marketplace and potentially identify profitable market offers. Our UI will aide users in not placing
     *       market offers that are obviously unfavorable to the user and/or seem like mistake orders. In the event that a user needs to cancel an offer, it is recommended to
     *       use Flashbots in order to privately send your transaction so an attack cannot be triggered from monitoring the mempool for calls to cancelOffer. A user is recommended
     *       to change their RPC endpoint to point to https://rpc.flashbots.net when calling cancelOffer. We will add additional documentation to aide our users in this process.
     *       More information on using Flashbots: https://docs.flashbots.net/flashbots-protect/rpc/quick-start/
     *
     * @param _offerId offer ID
     */
    function cancelOffer(uint256 _offerId) external notLocked(msg.sig) nonReentrant {
        require(LibMarket._getOffer(_offerId).state == LibConstants.OFFER_STATE_ACTIVE, "offer not active");
        bytes32 creator = LibMarket._getOffer(_offerId).creator;
        require(LibObject._getParent(LibHelpers._getIdForAddress(msg.sender)) == creator, "only member of entity can cancel");
        LibMarket._cancelOffer(_offerId);
    }

    /**
     * @notice Execute a limit offer.
     *
     * @param _sellToken Token to sell.
     * @param _sellAmount Amount to sell.
     * @param _buyToken Token to buy.
     * @param _buyAmount Amount to buy.
     * @return offerId_ returns >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the return value is the created offer's id.
     * @return buyTokenCommissionsPaid_ The amount of the buy token paid as commissions on this particular order.
     * @return sellTokenCommissionsPaid_ The amount of the sell token paid as commissions on this particular order.
     */
    function executeLimitOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    )
        external
        notLocked(msg.sig)
        nonReentrant
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        )
    {
        // Get the msg.sender's entityId. The parent is the entityId associated with the child, aka the msg.sender.
        // note: Only the entity associated with the msg.sender can make an offer on the market
        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);
        return LibMarket._executeLimitOffer(parentId, _sellToken, _sellAmount, _buyToken, _buyAmount, LibConstants.FEE_SCHEDULE_STANDARD);
    }

    /**
     * @dev Get last created offer.
     *
     * @return offer id.
     */
    function getLastOfferId() external view returns (uint256) {
        return LibMarket._getLastOfferId();
    }

    /**
     * @notice Get current best offer for given token pair.
     *
     * @dev This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken
     * @param _sellToken ID of the token being sold
     * @param _buyToken ID of the token being bought
     * @return offerId, or 0 if no offer exists for given pair
     */
    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256) {
        return LibMarket._getBestOfferId(_sellToken, _buyToken);
    }

    /**
     * @dev Get the details of the offer #`_offerId`
     * @param _offerId ID of a particular offer
     * @return _offerState details of the offer
     */
    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState) {
        return LibMarket._getOffer(_offerId);
    }

    /**
     * @dev Check if the offer #`_offerId` is active or not.
     * @param _offerId ID of a particular offer
     * @return active or not
     */
    function isActiveOffer(uint256 _offerId) external view returns (bool) {
        return LibMarket._isActiveOffer(_offerId);
    }

    /**
     * @dev Calculate the trading commissions based on a buy amount.
     * @param buyAmount The amount that the commissions payments are calculated from.
     * @return tc TradingCommissions struct
     */
    function calculateTradingCommissions(uint256 buyAmount) external view returns (TradingCommissions memory tc) {
        tc = LibFeeRouter._calculateTradingCommissions(buyAmount);
    }

    function getTradingCommissionsBasisPoints() external view returns (TradingCommissionsBasisPoints memory bp) {
        bp = LibFeeRouter._getTradingCommissionsBasisPoints();
    }
}