pragma solidity ^0.5.16;

import "../ApeToken.sol";

contract PriceOracle {
    /**
     * @notice Get the underlying price of a apeToken asset
     * @param apeToken The apeToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(ApeToken apeToken) external view returns (uint256);
}