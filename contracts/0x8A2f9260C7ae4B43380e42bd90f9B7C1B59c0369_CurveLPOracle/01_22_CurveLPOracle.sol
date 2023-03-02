// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IERC20.sol";
import "Ownable.sol";

import "Types.sol";
import "ScaledMath.sol";
import "ScaledMath.sol";
import "CurvePoolUtils.sol";
import "IOracle.sol";
import "IController.sol";
import "ICurveFactory.sol";
import "ICurvePoolV0.sol";
import "ICurvePoolV1.sol";
import "ICurveMetaRegistry.sol";

contract CurveLPOracle is IOracle, Ownable {
    using ScaledMath for uint256;

    event ImbalanceThresholdUpdated(address indexed token, uint256 threshold);

    uint256 internal constant _DEFAULT_IMBALANCE_THRESHOLD = 0.02e18;
    uint256 internal constant _MAX_IMBALANCE_THRESHOLD = 0.1e18;
    mapping(address => uint256) public imbalanceThresholds;

    IOracle private immutable _genericOracle;
    IController private immutable controller;

    constructor(address genericOracle, address controller_) {
        _genericOracle = IOracle(genericOracle);
        controller = IController(controller_);
    }

    function isTokenSupported(address token) external view override returns (bool) {
        address pool = _getCurvePool(token);
        ICurveRegistryCache curveRegistryCache_ = controller.curveRegistryCache();
        if (!curveRegistryCache_.isRegistered(pool)) return false;
        address[] memory coins = curveRegistryCache_.coins(pool);
        for (uint256 i; i < coins.length; i++) {
            if (!_genericOracle.isTokenSupported(coins[i])) return false;
        }
        return true;
    }

    function getUSDPrice(address token) external view returns (uint256) {
        // Getting the pool data
        address pool = _getCurvePool(token);
        ICurveRegistryCache curveRegistryCache_ = controller.curveRegistryCache();
        require(curveRegistryCache_.isRegistered(pool), "token not supported");
        uint256[] memory decimals = curveRegistryCache_.decimals(pool);
        address[] memory coins = curveRegistryCache_.coins(pool);

        // Adding up the USD value of all the coins in the pool
        uint256 value;
        uint256 numberOfCoins = curveRegistryCache_.nCoins(pool);
        uint256[] memory prices = new uint256[](numberOfCoins);
        uint256[] memory thresholds = new uint256[](numberOfCoins);
        for (uint256 i; i < numberOfCoins; i++) {
            address coin = coins[i];
            uint256 price = _genericOracle.getUSDPrice(coin);
            prices[i] = price;
            thresholds[i] = imbalanceThresholds[token];
            require(price > 0, "price is 0");
            uint256 balance = _getBalance(pool, i);
            require(balance > 0, "balance is 0");
            value += balance.convertScale(uint8(decimals[i]), 18).mulDown(price);
        }

        // Verifying the pool is balanced
        CurvePoolUtils.ensurePoolBalanced(
            CurvePoolUtils.PoolMeta({
                pool: pool,
                numberOfCoins: numberOfCoins,
                assetType: curveRegistryCache_.assetType(pool),
                decimals: decimals,
                prices: prices,
                thresholds: thresholds
            })
        );

        // Returning the value of the pool in USD per LP Token
        return value.divDown(IERC20(token).totalSupply());
    }

    function setImbalanceThreshold(address token, uint256 threshold) external onlyOwner {
        require(threshold <= _MAX_IMBALANCE_THRESHOLD, "threshold too high");
        imbalanceThresholds[token] = threshold;
        emit ImbalanceThresholdUpdated(token, threshold);
    }

    function _getCurvePool(address lpToken_) internal view returns (address) {
        return controller.curveRegistryCache().poolFromLpToken(lpToken_);
    }

    function _getBalance(address curvePool, uint256 index) internal view returns (uint256) {
        if (controller.curveRegistryCache().interfaceVersion(curvePool) == 0) {
            return ICurvePoolV0(curvePool).balances(int128(uint128(index)));
        }
        return ICurvePoolV1(curvePool).balances(index);
    }
}