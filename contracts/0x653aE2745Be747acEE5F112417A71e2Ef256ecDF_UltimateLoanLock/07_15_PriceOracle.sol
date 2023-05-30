pragma solidity ^0.5.16;

import "./XToken.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
     * @notice Get the underlying price of a xToken asset
     * @param xToken The xToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(XToken xToken) external returns (uint256);

    function assetPrices(address asset) external returns (uint256);
}