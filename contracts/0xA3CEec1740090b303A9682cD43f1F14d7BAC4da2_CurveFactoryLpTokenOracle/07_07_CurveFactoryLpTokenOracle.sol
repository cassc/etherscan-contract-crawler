// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/periphery/ITokenOracle.sol";
import "../../interfaces/external/curve/ICurveAddressProvider.sol";
import "../../interfaces/external/curve/ICurveFactoryRegistry.sol";
import "../../interfaces/external/curve/ICurvePool.sol";
import "../../interfaces/periphery/IOracle.sol";

/**
 * @title Oracle for Curve LP tokens (Factory Pools)
 */
contract CurveFactoryLpTokenOracle is ITokenOracle {
    /// @dev Same address for all chains
    ICurveAddressProvider public constant addressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

    /// @notice Factory Registry contract
    ICurveFactoryRegistry public immutable registry;

    /// @notice LP token => coins mapping
    mapping(address => address[]) public underlyingTokens;

    constructor() {
        registry = ICurveFactoryRegistry(addressProvider.get_address(3));
    }

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address lpToken_) public view override returns (uint256 _priceInUsd) {
        address[] memory _tokens = underlyingTokens[lpToken_];
        require(_tokens.length > 0, "lp-is-not-registered");
        uint256 _min = type(uint256).max;
        uint256 _n = _tokens.length;

        for (uint256 i; i < _n; i++) {
            uint256 _price = IOracle(msg.sender).getPriceInUsd(_tokens[i]);
            if (_price < _min) _min = _price;
        }

        require(_min < type(uint256).max, "no-min-underlying-price-found");
        require(_min > 0, "invalid-min-price");

        return (_min * ICurvePool(lpToken_).get_virtual_price()) / 1e18;
    }

    /// @notice Register LP token data
    /// @dev For factory pools, the LP and pool addresses are the same
    function registerPool(address pool_) external {
        require(underlyingTokens[pool_].length == 0, "lp-already-registered");

        uint256 _n = registry.get_n_coins(pool_);
        if (_n == 0) (_n, ) = registry.get_meta_n_coins(pool_);
        require(_n > 0, "invalid-pool");

        address[4] memory _tokens = registry.get_coins(pool_);
        for (uint256 i; i < _n; i++) {
            underlyingTokens[pool_].push(_tokens[i]);
        }
    }
}