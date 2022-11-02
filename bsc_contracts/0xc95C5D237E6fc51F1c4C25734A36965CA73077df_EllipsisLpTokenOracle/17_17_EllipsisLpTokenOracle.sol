// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/external/ellipsis/IEllipsisRegistry.sol";
import "./CurveLpTokenOracle.sol";

/**
 * @title Oracle for Ellipsis LP tokens
 */
contract EllipsisLpTokenOracle is CurveLpTokenOracle {
    constructor(ICurveAddressProvider addressProvider_) CurveLpTokenOracle(addressProvider_) {}

    /// @notice Register LP token data
    function _registerLp(address lpToken_, bool isLending_) internal override {
        IEllipsisRegistry _registry = IEllipsisRegistry(registry);
        address _pool = _registry.get_pool_from_lp_token(lpToken_);
        require(_pool != address(0), "invalid-non-factory-lp");

        address[4] memory _tokens = _registry.get_coins(_pool);

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