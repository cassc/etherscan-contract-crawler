// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IConfiguration {
    /// @notice Emitted when the feature changes it's state.
    event FeatureChanged(uint8 indexed feature, bool value);

    function setFeature(uint8 feature, bool value) external;

    function getFeatures() external view returns (uint256);

    function getFeature(uint8 feature) external view returns (bool);
}