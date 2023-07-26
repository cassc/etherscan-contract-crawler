// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.
pragma solidity 0.7.6;

/// @notice IGyroConfig stores the global configuration of the Gyroscope protocol
interface IGyroConfig {
    /// @notice Event emitted every time a configuration is changed
    event ConfigChanged(bytes32 key, uint256 previousValue, uint256 newValue);
    event ConfigChanged(bytes32 key, address previousValue, address newValue);

    /// @notice Returns a set of known configuration keys
    function listKeys() external view returns (bytes32[] memory);

    /// @notice Returns a uint256 value from the config
    function getUint(bytes32 key) external view returns (uint256);

    /// @notice Returns an address value from the config
    function getAddress(bytes32 key) external view returns (address);

    /// @notice Set a uint256 config
    /// NOTE: We avoid overloading to avoid complications with some clients
    function setUint(bytes32 key, uint256 newValue) external;

    /// @notice Check whether a key exists
    function hasKey(bytes32 key) external view returns (bool);

    /// @notice Set an address config
    function setAddress(bytes32 key, address newValue) external;
}