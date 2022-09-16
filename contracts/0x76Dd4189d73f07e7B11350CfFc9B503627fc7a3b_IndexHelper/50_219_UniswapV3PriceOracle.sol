// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";
import "./libraries/FixedPoint112.sol";
import "./interfaces/IUniswapV3PriceOracle.sol";

/// @title Uniswap V3 price oracle
/// @notice Contains logic for price calculation of assets using Uniswap V3 Pool
/// @dev Oracle works through base asset which is set in initialize function
contract UniswapV3PriceOracle is IUniswapV3PriceOracle, ERC165 {
    using ERC165Checker for address;
    using FullMath for uint;

    /// @notice Role allows configure asset related data/components
    bytes32 internal immutable ASSET_MANAGER_ROLE;

    /// @notice Index registry address
    IAccessControl internal immutable registry;

    /// @notice Uniswap pool of the two assets
    IUniswapV3Pool public immutable pool;

    /// @notice Asset0 in the pool
    address public immutable asset0;

    /// @notice Asset1 in the pool
    address public immutable asset1;

    /// @notice Twap interval
    uint32 public twapInterval;

    constructor(
        address _factory,
        address _assetA,
        address _assetB,
        uint24 _fee,
        uint32 _twapInterval,
        address _registry
    ) {
        require(_registry.supportsInterface(type(IAccessControl).interfaceId), "UniswapV3PriceOracle: INTERFACE");
        ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
        registry = IAccessControl(_registry);

        IUniswapV3Pool _pool = IUniswapV3Pool(IUniswapV3Factory(_factory).getPool(_assetA, _assetB, _fee));
        pool = _pool;
        asset0 = _pool.token0();
        asset1 = _pool.token1();
        twapInterval = _twapInterval;
    }

    /// @inheritdoc IUniswapV3PriceOracle
    function setTwapInterval(uint32 _twapInterval) external {
        require(registry.hasRole(ASSET_MANAGER_ROLE, msg.sender), "UniswapV3PriceOracle: FORBIDDEN");
        twapInterval = _twapInterval;
    }

    /// @inheritdoc IPriceOracle
    /// @notice Returns average asset per base
    function refreshedAssetPerBaseInUQ(address _asset) external view override returns (uint) {
        return getPriceInUQ(_asset, getSqrtTwapX96Asset0());
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view returns (uint) {
        return getPriceInUQ(_asset, getSqrtTwapX96Asset0());
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IUniswapV3PriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Gets square root of price in x96 format
    function getSqrtTwapX96Asset0() internal view returns (uint) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = twapInterval; // from (before)
        secondsAgo[1] = 0; // to (now)

        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgo);
        // The current price of the pool as a sqrt(asset1/asset0) Q64.96 value
        uint160 asset0sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
            int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(secondsAgo[0])))
        );
        return uint(asset0sqrtPriceX96);
    }

    /// @notice Gets price of asset in UQ format
    /// @param _asset Address of the asset
    /// @param _asset0sqrtPriceX96 Square root of price for asset0
    function getPriceInUQ(address _asset, uint _asset0sqrtPriceX96) internal view returns (uint _price) {
        // if asset == asset1 return price0Average
        if (_asset == asset1) {
            // (asset0sqrtPriceX96 * asset0sqrtPriceX96 / 2**192) * 2**112
            _price = _asset0sqrtPriceX96.mulDiv(_asset0sqrtPriceX96, 2**80);
        } else {
            require(_asset == asset0, "UniswapV3PriceOracle: UNKNOWN");
            // (2**192 / asset0sqrtPriceX96 * asset0sqrtPriceX96) * 2**112
            _price = (2**192 / _asset0sqrtPriceX96).mulDiv(FixedPoint112.Q112, _asset0sqrtPriceX96);
        }
        require(_price > 0, "UniswapV3PriceOracle: ZERO");
    }
}