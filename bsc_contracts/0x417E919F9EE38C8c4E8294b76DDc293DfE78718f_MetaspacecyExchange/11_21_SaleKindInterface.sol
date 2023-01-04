// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../math/SafeMath.sol";
import "./Market.sol";

library SaleKindInterface {
    using SafeMath for uint256;

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(
        Market.SaleKind saleKind,
        uint256 expirationTime
    ) internal pure returns (bool) {
        /* Auctions must have a set expiration date. */
        return (saleKind == Market.SaleKind.FixedPrice || expirationTime > 0);
    }
 
    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint256 listingTime, uint256 expirationTime)
        internal
        view
        returns (bool)
    {
        return
            (listingTime < block.timestamp) &&
            (expirationTime == 0 || block.timestamp < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(
        Market.Side side,
        Market.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    )
        internal
        view
        returns (uint256 finalPrice)
    {
        if (saleKind == Market.SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == Market.SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(block.timestamp, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Market.Side.Sell) {
                return SafeMath.sub(basePrice, diff);
            } else {
                return SafeMath.add(basePrice, diff);
            }
        }
    }
}