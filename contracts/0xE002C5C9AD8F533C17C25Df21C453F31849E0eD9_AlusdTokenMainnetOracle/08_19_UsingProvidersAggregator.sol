// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";
import "../interfaces/core/IPriceProvidersAggregator.sol";

/**
 * @title Providers Aggregators usage feature, useful for periphery oracles that need get prices from many providers
 */
abstract contract UsingProvidersAggregator is Governable {
    /// @notice The PriceProvidersAggregator contract
    IPriceProvidersAggregator public providersAggregator;

    /// @notice Emitted when providers aggregator is updated
    event ProvidersAggregatorUpdated(
        IPriceProvidersAggregator oldProvidersAggregator,
        IPriceProvidersAggregator newProvidersAggregator
    );

    constructor(IPriceProvidersAggregator providersAggregator_) {
        require(address(providersAggregator_) != address(0), "aggregator-is-null");
        providersAggregator = providersAggregator_;
    }

    /**
     * @notice Update PriceProvidersAggregator contract
     */
    function updateProvidersAggregator(IPriceProvidersAggregator providersAggregator_) external onlyGovernor {
        require(address(providersAggregator_) != address(0), "address-is-null");
        emit ProvidersAggregatorUpdated(providersAggregator, providersAggregator_);
        providersAggregator = providersAggregator_;
    }
}