// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../utils/DispatcherOwnerMixin.sol";
import "./IAggregatedDerivativePriceFeed.sol";

/// @title AggregatedDerivativePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Aggregates multiple derivative price feeds (e.g., Compound, Chai) and dispatches
/// rate requests to the appropriate feed
contract AggregatedDerivativePriceFeed is IAggregatedDerivativePriceFeed, DispatcherOwnerMixin {
    event DerivativeAdded(address indexed derivative, address priceFeed);

    event DerivativeRemoved(address indexed derivative);

    event DerivativeUpdated(
        address indexed derivative,
        address prevPriceFeed,
        address nextPriceFeed
    );

    mapping(address => address) private derivativeToPriceFeed;

    constructor(
        address _dispatcher,
        address[] memory _derivatives,
        address[] memory _priceFeeds
    ) public DispatcherOwnerMixin(_dispatcher) {
        if (_derivatives.length > 0) {
            __addDerivatives(_derivatives, _priceFeeds);
        }
    }

    /// @notice Gets the rates for 1 unit of the derivative to its underlying assets
    /// @param _derivative The derivative for which to get the rates
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The rates for the _derivative to the underlyings_
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        address derivativePriceFeed = derivativeToPriceFeed[_derivative];
        require(
            derivativePriceFeed != address(0),
            "calcUnderlyingValues: _derivative is not supported"
        );

        return
            IDerivativePriceFeed(derivativePriceFeed).calcUnderlyingValues(
                _derivative,
                _derivativeAmount
            );
    }

    /// @notice Checks whether an asset is a supported derivative
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is a supported derivative
    /// @dev This should be as low-cost and simple as possible
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return derivativeToPriceFeed[_asset] != address(0);
    }

    //////////////////////////
    // DERIVATIVES REGISTRY //
    //////////////////////////

    /// @notice Adds a list of derivatives with the given price feed values
    /// @param _derivatives The derivatives to add
    /// @param _priceFeeds The ordered price feeds corresponding to the list of _derivatives
    function addDerivatives(address[] calldata _derivatives, address[] calldata _priceFeeds)
        external
        onlyDispatcherOwner
    {
        require(_derivatives.length > 0, "addDerivatives: _derivatives cannot be empty");

        __addDerivatives(_derivatives, _priceFeeds);
    }

    /// @notice Removes a list of derivatives
    /// @param _derivatives The derivatives to remove
    function removeDerivatives(address[] calldata _derivatives) external onlyDispatcherOwner {
        require(_derivatives.length > 0, "removeDerivatives: _derivatives cannot be empty");

        for (uint256 i = 0; i < _derivatives.length; i++) {
            require(
                derivativeToPriceFeed[_derivatives[i]] != address(0),
                "removeDerivatives: Derivative not yet added"
            );

            delete derivativeToPriceFeed[_derivatives[i]];

            emit DerivativeRemoved(_derivatives[i]);
        }
    }

    /// @notice Updates a list of derivatives with the given price feed values
    /// @param _derivatives The derivatives to update
    /// @param _priceFeeds The ordered price feeds corresponding to the list of _derivatives
    function updateDerivatives(address[] calldata _derivatives, address[] calldata _priceFeeds)
        external
        onlyDispatcherOwner
    {
        require(_derivatives.length > 0, "updateDerivatives: _derivatives cannot be empty");
        require(
            _derivatives.length == _priceFeeds.length,
            "updateDerivatives: Unequal _derivatives and _priceFeeds array lengths"
        );

        for (uint256 i = 0; i < _derivatives.length; i++) {
            address prevPriceFeed = derivativeToPriceFeed[_derivatives[i]];

            require(prevPriceFeed != address(0), "updateDerivatives: Derivative not yet added");
            require(_priceFeeds[i] != prevPriceFeed, "updateDerivatives: Value already set");

            __validateDerivativePriceFeed(_derivatives[i], _priceFeeds[i]);

            derivativeToPriceFeed[_derivatives[i]] = _priceFeeds[i];

            emit DerivativeUpdated(_derivatives[i], prevPriceFeed, _priceFeeds[i]);
        }
    }

    /// @dev Helper to add derivative-feed pairs
    function __addDerivatives(address[] memory _derivatives, address[] memory _priceFeeds)
        private
    {
        require(
            _derivatives.length == _priceFeeds.length,
            "__addDerivatives: Unequal _derivatives and _priceFeeds array lengths"
        );

        for (uint256 i = 0; i < _derivatives.length; i++) {
            require(
                derivativeToPriceFeed[_derivatives[i]] == address(0),
                "__addDerivatives: Already added"
            );

            __validateDerivativePriceFeed(_derivatives[i], _priceFeeds[i]);

            derivativeToPriceFeed[_derivatives[i]] = _priceFeeds[i];

            emit DerivativeAdded(_derivatives[i], _priceFeeds[i]);
        }
    }

    /// @dev Helper to validate a derivative price feed
    function __validateDerivativePriceFeed(address _derivative, address _priceFeed) private view {
        require(_derivative != address(0), "__validateDerivativePriceFeed: Empty _derivative");
        require(_priceFeed != address(0), "__validateDerivativePriceFeed: Empty _priceFeed");
        require(
            IDerivativePriceFeed(_priceFeed).isSupportedAsset(_derivative),
            "__validateDerivativePriceFeed: Unsupported derivative"
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the registered price feed for a given derivative
    /// @return priceFeed_ The price feed contract address
    function getPriceFeedForDerivative(address _derivative)
        external
        view
        override
        returns (address priceFeed_)
    {
        return derivativeToPriceFeed[_derivative];
    }
}