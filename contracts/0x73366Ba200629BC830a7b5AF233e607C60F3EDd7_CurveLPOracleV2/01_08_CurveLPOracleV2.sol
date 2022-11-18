// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ProviderAwareOracle.sol";
import "../../interfaces/CurveTokenInterface.sol";
import "../../../lib/FixedPointMathLib.sol";

contract CurveLPOracleV2 is ProviderAwareOracle {

    using FixedPointMathLib for uint;

    constructor(address _provider) ProviderAwareOracle(_provider) {}

    function getSafePrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /// @dev Gets the safe price, no updates necessary
    function updateSafePrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /**
     * @notice Get price for curve pool tokens
     * @param token The curve pool token
     * @return The price
     */
    function getCrvTokenPrice(address token) internal view returns (uint256) {
        address minter = CurveTokenV3Interface(token).minter();

        return CurveLPPriceInterface(minter).lp_price();
    }

}