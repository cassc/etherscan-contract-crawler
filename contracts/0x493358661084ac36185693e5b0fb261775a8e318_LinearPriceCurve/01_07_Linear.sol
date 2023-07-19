//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {IPricingCurve} from "../../../interfaces/IPricingCurve.sol";
import {ITradingPoolFactory} from "../../../interfaces/ITradingPoolFactory.sol";
import {IAddressProvider} from "../../../interfaces/IAddressProvider.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {PercentageMath} from "../../../libraries/utils/PercentageMath.sol";

/// @title LinearPriceCurve Contract
/// @author leNFT
/// @notice Calculates the price of a token based on a linear curve
/// @dev Contract module using for linear price curve logic
contract LinearPriceCurve is IPricingCurve, ERC165 {
    IAddressProvider private immutable _addressProvider;

    constructor(IAddressProvider addressProvider) {
        _addressProvider = addressProvider;
    }

    /// @notice Calculates the price after buying 1 token
    /// @param price The current price of the token
    /// @param delta The delta factor to increase the price
    /// @return The updated price after buying
    function priceAfterBuy(
        uint256 price,
        uint256 delta,
        uint256
    ) external pure override returns (uint256) {
        return price + delta;
    }

    /// @notice Calculates the price after selling 1 token
    /// @param price The current price of the token
    /// @param delta The delta factor to decrease the price
    /// @return The updated price after selling
    function priceAfterSell(
        uint256 price,
        uint256 delta,
        uint256 fee
    ) external view override returns (uint256) {
        // So we can't go to negative prices
        if (delta > price) {
            return price;
        }

        if (fee > 0 && delta > 0) {
            uint256 userFeePercentage = PercentageMath.percentMul(
                fee,
                PercentageMath.PERCENTAGE_FACTOR -
                    ITradingPoolFactory(
                        _addressProvider.getTradingPoolFactory()
                    ).getProtocolFeePercentage()
            );

            // If the next price makes it so the next buy price is lower than the current sell price we dont update
            if (
                (price - delta) *
                    (PercentageMath.PERCENTAGE_FACTOR + userFeePercentage) >
                price * (PercentageMath.PERCENTAGE_FACTOR - userFeePercentage)
            ) {
                return price - delta;
            } else {
                return price;
            }
        }

        return price - delta;
    }

    /// @notice Validates the parameters for a liquidity provider deposit
    /// @param spotPrice The initial spot price of the LP
    /// @param delta The delta of the LP
    /// @param fee The fee of the LP
    function validateLpParameters(
        uint256 spotPrice,
        uint256 delta,
        uint256 fee
    ) external view override {
        require(spotPrice > 0, "LPC:VLPP:INVALID_PRICE");
        require(delta < spotPrice, "LPC:VLPP:INVALID_DELTA");

        if (fee > 0 && delta > 0) {
            uint256 userFeePercentage = PercentageMath.percentMul(
                fee,
                PercentageMath.PERCENTAGE_FACTOR -
                    ITradingPoolFactory(
                        _addressProvider.getTradingPoolFactory()
                    ).getProtocolFeePercentage()
            );
            // Make sure the LP can't be drained by buying and selling from the same LP
            require(
                (spotPrice - delta) *
                    (PercentageMath.PERCENTAGE_FACTOR + userFeePercentage) >
                    spotPrice *
                        (PercentageMath.PERCENTAGE_FACTOR - userFeePercentage),
                "LPC:VLPP:INVALID_FEE_DELTA_RATIO"
            );
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IPricingCurve).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}