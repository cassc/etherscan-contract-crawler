// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ProviderAwareOracle.sol";
import "../../interfaces/CurveTokenInterface.sol";
import "../../../lib/FixedPointMathLib.sol";

contract CurvePoolOracle is ProviderAwareOracle {

    using FixedPointMathLib for uint;

    mapping(address => address) public pools;
    address public immutable conversionAsset;

    constructor(address _provider, address _conversionAsset) ProviderAwareOracle(_provider) {
        require(provider.getSafePrice(_conversionAsset) != 0);
        conversionAsset = _conversionAsset;
    }

    function setPool(address token, address pool) external onlyOwner {
        require(CurveSwapInterface(pool).get_virtual_price() != 0, "Error with Curve Pool");
        pools[token] = pool;
    }

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
        address pool = pools[token];
        require(pool != address(0), "Unsupported token");

        uint256 virtualPrice = CurveSwapInterface(pool).get_virtual_price();

        uint256 conversionPrice = provider.getSafePrice(conversionAsset);
        // 1 * yCRV/CRV * CRV/ETH 
        return virtualPrice * conversionPrice / 1e18;
    }

}