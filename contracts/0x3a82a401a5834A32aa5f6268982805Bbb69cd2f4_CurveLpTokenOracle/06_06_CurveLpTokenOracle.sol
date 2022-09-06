// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/periphery/ITokenOracle.sol";
import "../../interfaces/external/curve/ICurveAddressProvider.sol";
import "../../interfaces/external/curve/ICurveRegistry.sol";
import "../../interfaces/external/curve/ICurvePool.sol";
import "../../interfaces/periphery/IOracle.sol";

/**
 * @title Oracle for Curve LP tokens
 */
contract CurveLpTokenOracle is ITokenOracle {
    /// @dev Same address for all chains
    ICurveAddressProvider public constant addressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

    /// @notice Registry contract
    ICurveRegistry public immutable registry;

    /// @notice LP token => coins mapping
    mapping(address => address[]) public underlyingTokens;

    /// @notice LP token => pool
    mapping(address => address) public poolOf;

    constructor() {
        registry = ICurveRegistry(addressProvider.get_registry());
    }

    /// @inheritdoc ITokenOracle
    /// @dev This function is supposed to be called from `MasterOracle` only
    function getPriceInUsd(address lpToken_) public view override returns (uint256 _priceInUsd) {
        address _pool = poolOf[lpToken_];
        require(_pool != address(0), "lp-is-not-registered");
        address[] memory _tokens = underlyingTokens[lpToken_];
        uint256 _min = type(uint256).max;
        uint256 _n = _tokens.length;

        for (uint256 i; i < _n; i++) {
            // Note: `msg.sender` is the `MasterOracle` contract
            uint256 _price = IOracle(msg.sender).getPriceInUsd(_tokens[i]);
            if (_price < _min) _min = _price;
        }

        require(_min < type(uint256).max, "no-min-underlying-price-found");
        require(_min > 0, "invalid-min-price");

        return (_min * ICurvePool(_pool).get_virtual_price()) / 1e18;
    }

    /// @notice Register LP token data
    function registerPool(address lpToken_) external {
        address _pool = poolOf[lpToken_];
        require(_pool == address(0), "lp-already-registered");

        _pool = registry.get_pool_from_lp_token(lpToken_);
        require(_pool != address(0), "invalid-non-factory-lp");

        poolOf[lpToken_] = _pool;

        uint256 _n = registry.get_n_coins(_pool);
        address[8] memory tokens = registry.get_coins(_pool);
        for (uint256 i; i < _n; i++) {
            underlyingTokens[lpToken_].push(tokens[i]);
        }
    }
}