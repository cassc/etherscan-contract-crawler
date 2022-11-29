pragma solidity 0.5.16;

import "../BToken.sol";

contract PriceOracle {
    /**
     * @notice Get the underlying price of a bToken asset
     * @param bToken The bToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(BToken bToken) external view returns (uint256);
}