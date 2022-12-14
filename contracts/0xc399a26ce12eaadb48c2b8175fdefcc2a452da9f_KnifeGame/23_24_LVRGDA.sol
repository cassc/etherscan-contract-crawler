// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LogisticVRGDA} from "VRGDAs/LogisticVRGDA.sol";

// LogisticVRGDA is an abstract contract, need to wrap it like so
contract LVRGDA is LogisticVRGDA {
    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _maxSellable The maximum number of tokens to sell, scaled by 1e18.
    /// @param _timeScale The steepness of the logistic curve, scaled by 1e18.
    constructor(int256 _targetPrice, int256 _priceDecayPercent, int256 _maxSellable, int256 _timeScale)
        LogisticVRGDA(_targetPrice, _priceDecayPercent, _maxSellable, _timeScale)
    {}
}