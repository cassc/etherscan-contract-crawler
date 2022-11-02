// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/periphery/ITokenOracle.sol";
import "../../interfaces/external/curve/ICurveAddressProvider.sol";
import "../../interfaces/external/curve/ICurveRegistry.sol";
import "../../interfaces/external/curve/ICurvePool.sol";
import "../../interfaces/periphery/IOracle.sol";
import "../../access/Governable.sol";

/**
 * @title Oracle for Curve LP tokens
 */
contract CurveLpTokenOracle is ITokenOracle, Governable {
    ICurveAddressProvider public immutable curveAddressProvider;

    /// @notice Registry contract
    address public immutable registry;

    /// @notice LP token => coins mapping
    mapping(address => address[]) public underlyingTokens;

    /// @notice LP token => pool
    mapping(address => address) public poolOf;

    /// @notice Emitted when a token is registered
    event LpRegistered(address indexed lpToken, bool isLending);

    constructor(ICurveAddressProvider curveAddressProvider_) {
        require(address(curveAddressProvider_) != address(0), "null-address-provider");
        curveAddressProvider = curveAddressProvider_;
        registry = curveAddressProvider.get_registry();
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
    function registerLp(address lpToken_) external onlyGovernor {
        _registerLp(lpToken_, false);
    }

    /// @notice Register LP token data
    function registerLendingLp(address lpToken_) external onlyGovernor {
        _registerLp(lpToken_, true);
    }

    /// @notice Register LP token data
    function _registerLp(address lpToken_, bool isLending_) internal virtual {
        ICurveRegistry _registry = ICurveRegistry(registry);
        address _pool = _registry.get_pool_from_lp_token(lpToken_);
        require(_pool != address(0), "invalid-non-factory-lp");

        address[8] memory _tokens;
        if (isLending_) {
            _tokens = _registry.get_underlying_coins(_pool);
        } else {
            _tokens = _registry.get_coins(_pool);
        }

        if (poolOf[lpToken_] != address(0)) {
            // Clean current tokens if LP exists
            delete underlyingTokens[lpToken_];
        }

        poolOf[lpToken_] = _pool;

        uint256 _n = _registry.get_n_coins(_pool);
        for (uint256 i; i < _n; i++) {
            underlyingTokens[lpToken_].push(_tokens[i]);
        }

        emit LpRegistered(lpToken_, isLending_);
    }
}