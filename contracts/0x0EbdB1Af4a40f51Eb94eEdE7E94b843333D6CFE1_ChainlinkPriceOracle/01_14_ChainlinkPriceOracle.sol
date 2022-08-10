// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "./libraries/FullMath.sol";
import "./libraries/FixedPoint112.sol";

import "./interfaces/IChainlinkPriceOracle.sol";

/// @title Chainlink price oracle
/// @notice Contains logic for getting asset's price from Chainlink data feed
/// @dev Oracle works through base asset which is set in initialize function
contract ChainlinkPriceOracle is IChainlinkPriceOracle, ERC165 {
    using FullMath for uint;
    using ERC165Checker for address;

    struct AssetInfo {
        address[] aggregators;
        uint8 decimals;
    }

    /// @notice Role allows configure asset related data/components
    bytes32 internal immutable ASSET_MANAGER_ROLE;

    /// @notice Infos of added assets
    mapping(address => AssetInfo) internal assetInfoOf;

    /// @notice Index registry address
    IAccessControl internal immutable registry;

    /// @notice Chainlink aggregator for the base asset
    AggregatorV2V3Interface internal immutable baseAggregator;

    /// @notice Number of decimals in base asset
    uint8 internal immutable baseDecimals;

    /// @notice Number of decimals in base asset answer
    uint8 internal immutable baseAnswerDecimals;

    /// @notice Number of decimals in answer of aggregator
    mapping(address => uint) internal answerDecimals;

    /// @inheritdoc IChainlinkPriceOracle
    uint public maxUpdateInterval;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(registry.hasRole(_role, msg.sender), "ChainlinkPriceOracle: FORBIDDEN");
        _;
    }

    constructor(
        address _registry,
        address _base,
        address _baseAggregator,
        uint _maxUpdateInterval
    ) {
        require(_base != address(0) && _baseAggregator != address(0), "ChainlinkPriceOracle: ZERO");
        require(_registry.supportsInterface(type(IAccessControl).interfaceId), "ChainlinkPriceOracle: INTERFACE");

        ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

        registry = IAccessControl(_registry);
        baseAnswerDecimals = AggregatorV2V3Interface(_baseAggregator).decimals();
        baseDecimals = IERC20Metadata(_base).decimals();
        baseAggregator = AggregatorV2V3Interface(_baseAggregator);
        maxUpdateInterval = _maxUpdateInterval;

        emit SetMaxUpdateInterval(msg.sender, _maxUpdateInterval);
    }

    /// @inheritdoc IChainlinkPriceOracle
    function setMaxUpdateInterval(uint _maxUpdateInterval) external override onlyRole(ASSET_MANAGER_ROLE) {
        maxUpdateInterval = _maxUpdateInterval;
        emit SetMaxUpdateInterval(msg.sender, _maxUpdateInterval);
    }

    /// @inheritdoc IChainlinkPriceOracle
    function addAsset(address _asset, address _assetAggregator) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(_asset != address(0), "ChainlinkPriceOracle: ZERO");

        address[] memory aggregators = new address[](1);
        aggregators[0] = _assetAggregator;

        assetInfoOf[_asset] = AssetInfo({ aggregators: aggregators, decimals: IERC20Metadata(_asset).decimals() });
        answerDecimals[_assetAggregator] = AggregatorV2V3Interface(_assetAggregator).decimals();

        emit AssetAdded(_asset, aggregators);
    }

    /// @inheritdoc IChainlinkPriceOracle
    function addAsset(address _asset, address[] memory _assetAggregators)
        external
        override
        onlyRole(ASSET_MANAGER_ROLE)
    {
        uint aggregatorsCount = _assetAggregators.length;
        require(_asset != address(0) && aggregatorsCount != 0, "ChainlinkPriceOracle: INVALID");

        assetInfoOf[_asset] = AssetInfo({
            aggregators: _assetAggregators,
            decimals: IERC20Metadata(_asset).decimals()
        });

        for (uint i; i < aggregatorsCount; ) {
            address aggregator = _assetAggregators[i];

            answerDecimals[aggregator] = AggregatorV2V3Interface(aggregator).decimals();

            unchecked {
                i = i + 1;
            }
        }

        emit AssetAdded(_asset, _assetAggregators);
    }

    /// @inheritdoc IPriceOracle
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint) {
        return _assetPerBaseInUQ(_asset);
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view override returns (uint) {
        return _assetPerBaseInUQ(_asset);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IChainlinkPriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Returns asset price
    function _assetPerBaseInUQ(address _asset) internal view returns (uint) {
        AssetInfo storage assetInfo = assetInfoOf[_asset];

        uint basePrice = _getPrice(baseAggregator);

        uint assetPerBaseInUQ;

        uint aggregatorsCount = assetInfo.aggregators.length;
        for (uint i; i < aggregatorsCount; ) {
            address aggregator = assetInfo.aggregators[i];
            uint quotePrice = _getPrice(AggregatorV2V3Interface(aggregator));

            if (i == 0) {
                assetPerBaseInUQ =
                    ((10**assetInfo.decimals * basePrice).mulDiv(FixedPoint112.Q112, quotePrice * 10**baseDecimals) *
                        10**answerDecimals[aggregator]) /
                    10**baseAnswerDecimals;
            } else {
                assetPerBaseInUQ = (assetPerBaseInUQ / quotePrice) * 10**answerDecimals[aggregator];
            }

            unchecked {
                i = i + 1;
            }
        }

        return assetPerBaseInUQ;
    }

    /// @notice Returns price from chainlink
    function _getPrice(AggregatorV2V3Interface _aggregator) internal view returns (uint) {
        (uint80 roundID, int price, , uint updatedAt, uint80 answeredInRound) = _aggregator.latestRoundData();
        if (updatedAt == 0 || price < 1 || answeredInRound < roundID) {
            if (roundID != 0) {
                (roundID, price, , updatedAt, answeredInRound) = _aggregator.getRoundData(roundID - 1);
            }

            require(updatedAt != 0 && price > 0 && answeredInRound >= roundID, "ChainlinkPriceOracle: STALE");
        }
        require(maxUpdateInterval > block.timestamp - updatedAt, "ChainlinkPriceOracle: INTERVAL");

        return uint(price);
    }
}