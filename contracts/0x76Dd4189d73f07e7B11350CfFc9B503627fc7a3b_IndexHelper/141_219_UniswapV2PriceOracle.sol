// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/UniswapV2OracleLibrary.sol";

import "./interfaces/IUniswapV2PriceOracle.sol";

/// @title Uniswap V2 price oracle
/// @notice Contains logic for price calculation of asset using Uniswap V2 Pair
/// @dev Oracle works through base asset which is set in initialize function
contract UniswapV2PriceOracle is IUniswapV2PriceOracle, ERC165 {
    using ERC165Checker for address;
    using UniswapV2OracleLibrary for address;

    /// @notice Role allows configure asset related data/components
    bytes32 internal immutable ASSET_MANAGER_ROLE;

    /// @notice Index registry address
    IAccessControl internal immutable registry;

    IUniswapV2Pair immutable pair;
    /// @inheritdoc IUniswapV2PriceOracle
    address public immutable override asset0;
    /// @inheritdoc IUniswapV2PriceOracle
    address public immutable override asset1;

    uint32 internal blockTimestampLast;

    uint internal price0CumulativeLast;
    uint internal price1CumulativeLast;
    uint internal price0Average;
    uint internal price1Average;

    /// @inheritdoc IUniswapV2PriceOracle
    uint public override minUpdateInterval;

    constructor(
        address _factory,
        address _assetA,
        address _assetB,
        address _registry,
        uint _minUpdateInterval
    ) {
        require(_registry.supportsInterface(type(IAccessControl).interfaceId), "UniswapV2PriceOracle: INTERFACE");

        ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

        registry = IAccessControl(_registry);
        minUpdateInterval = _minUpdateInterval;

        IUniswapV2Pair _pair = IUniswapV2Pair(IUniswapV2Factory(_factory).getPair(_assetA, _assetB));
        pair = _pair;
        asset0 = _pair.token0();
        asset1 = _pair.token1();

        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "UniswapV2PriceOracle: RESERVES");

        uint _price0CumulativeLast = _pair.price0CumulativeLast();
        uint _price1CumulativeLast = _pair.price1CumulativeLast();
        (uint price0Cml, uint price1Cml, uint32 blockTimestamp) = address(_pair).currentCumulativePrices();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        price0CumulativeLast = _price0CumulativeLast;
        price1CumulativeLast = _price1CumulativeLast;
        price0Average = (price0Cml - _price0CumulativeLast) / timeElapsed;
        price1Average = (price1Cml - _price1CumulativeLast) / timeElapsed;
    }

    /// @inheritdoc IUniswapV2PriceOracle
    /// @dev Requires msg.sender to have `_role` role
    function setMinUpdateInterval(uint _minUpdateInterval) external override {
        require(registry.hasRole(ASSET_MANAGER_ROLE, msg.sender), "UniswapV2PriceOracle: FORBIDDEN");
        minUpdateInterval = _minUpdateInterval;
    }

    /// @inheritdoc IPriceOracle
    /// @dev Updates and returns cumulative price value
    /// @dev If min update interval hasn't passed (24h), previously cached value is returned
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = address(pair).currentCumulativePrices();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed >= minUpdateInterval) {
            price0Average = (price0Cumulative - price0CumulativeLast) / timeElapsed;
            price1Average = (price1Cumulative - price1CumulativeLast) / timeElapsed;

            price0CumulativeLast = price0Cumulative;
            price1CumulativeLast = price1Cumulative;
            blockTimestampLast = blockTimestamp;
        }

        return lastAssetPerBaseInUQ(_asset);
    }

    /// @inheritdoc IPriceOracle
    /// @dev Returns cumulative price value cached during last refresh call
    function lastAssetPerBaseInUQ(address _asset) public view override returns (uint _price) {
        if (_asset == asset0) {
            _price = price1Average;
        } else {
            require(_asset == asset1, "UniswapV2PriceOracle: UNKNOWN");

            _price = price0Average;
        }
        require(_price > 0, "UniswapV2PriceOracle: ZERO");
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IPriceOracle).interfaceId ||
            _interfaceId == type(IUniswapV2PriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}