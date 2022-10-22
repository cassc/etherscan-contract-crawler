// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/core/IChainlinkPriceProvider.sol";
import "./PriceProvider.sol";
import "../access/Governable.sol";

/**
 * @title ChainLink's price provider
 * @dev This contract wraps chainlink aggregators
 */
contract ChainlinkPriceProvider is IChainlinkPriceProvider, PriceProvider, Governable {
    using SafeCast for int256;

    uint256 public constant CHAINLINK_DECIMALS = 8;
    uint256 public constant TO_SCALE = 10**(USD_DECIMALS - CHAINLINK_DECIMALS);

    /**
     * @notice Aggregators map (token => aggregator)
     */
    mapping(address => AggregatorV3Interface) public aggregators;

    /// Emitted when an aggregator is updated
    event AggregatorUpdated(address token, AggregatorV3Interface oldAggregator, AggregatorV3Interface newAggregator);

    /// @inheritdoc IPriceProvider
    function getPriceInUsd(address token_)
        public
        view
        virtual
        override(IPriceProvider, PriceProvider)
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        AggregatorV3Interface _aggregator = aggregators[token_];
        require(address(_aggregator) != address(0), "token-without-aggregator");
        int256 _price;
        (, _price, , _lastUpdatedAt, ) = _aggregator.latestRoundData();
        return (_price.toUint256() * TO_SCALE, _lastUpdatedAt);
    }

    /// @inheritdoc IChainlinkPriceProvider
    function updateAggregator(address token_, AggregatorV3Interface aggregator_) external override onlyGovernor {
        require(token_ != address(0), "token-is-null");
        AggregatorV3Interface _current = aggregators[token_];
        require(aggregator_ != _current, "same-as-current");
        _setAggregator(token_, aggregator_);
        emit AggregatorUpdated(token_, _current, aggregator_);
    }

    function _setAggregator(address token_, AggregatorV3Interface aggregator_) internal {
        require(address(aggregator_) == address(0) || aggregator_.decimals() == CHAINLINK_DECIMALS, "invalid-decimals");
        aggregators[token_] = aggregator_;
    }
}