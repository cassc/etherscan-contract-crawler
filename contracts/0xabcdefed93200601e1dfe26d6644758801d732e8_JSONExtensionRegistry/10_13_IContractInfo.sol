// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IContractInfo {
    /// @notice Contract version
    function version() external view returns (uint256);

    /// @notice Contract Name Getter
    /// @dev Used to identify contract
    /// @return string contract name
    function name() external pure returns (string memory);

    /// @notice Contract Information URI Getter
    /// @dev Used to provide contract information
    /// @return string contract information uri
    function contractInfo() external pure returns (string memory);
}