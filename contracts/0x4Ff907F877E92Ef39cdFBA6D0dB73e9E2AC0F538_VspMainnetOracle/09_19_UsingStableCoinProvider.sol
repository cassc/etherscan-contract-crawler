// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";
import "../interfaces/core/IStableCoinProvider.sol";

/**
 * @title Stable coin provider usage feature, useful for contract that need a pegged USD stable coin
 */
abstract contract UsingStableCoinProvider is Governable {
    /// @notice The StableCoinProvider contract
    IStableCoinProvider public stableCoinProvider;

    /// @notice Emitted when stable coin provider is updated
    event StableCoinProviderUpdated(
        IStableCoinProvider oldStableCoinProvider,
        IStableCoinProvider newStableCoinProvider
    );

    constructor(IStableCoinProvider stableCoinProvider_) {
        stableCoinProvider = stableCoinProvider_;
    }

    /**
     * @notice Update StableCoinProvider contract
     */
    function updateStableCoinProvider(IStableCoinProvider stableCoinProvider_) external onlyGovernor {
        emit StableCoinProviderUpdated(stableCoinProvider, stableCoinProvider_);
        stableCoinProvider = stableCoinProvider_;
    }
}