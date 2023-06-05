// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

/// @title ICollector
/// @author Giveth developers
/// @notice Interface of the Collector contract.
interface ICollector {
    ///
    /// ADMIN FUNCTIONS:
    ///

    /// @notice Change the beneficiary address.
    /// @dev Can only be called by the owner. Beneficiary cannot be address zero.
    /// @param beneficiaryAddr The new beneficiary.
    function changeBeneficiary(address beneficiaryAddr) external;

    ///
    /// EXTERNAL FUNCTIONS:
    ///

    /// @notice Withdraw all the collected ETH.
    /// @dev Can only be called by the beneficiary.
    function withdraw() external;

    /// @notice Withdraw all the collected tokens from the given token contract.
    /// @dev Can only be called by the beneficiary. Token must be a valid ERC20 contract.
    /// @param token Token contract address.
    function withdrawTokens(address token) external;

    ///
    /// VIEW FUNCTIONS;
    ///

    /// @notice Returns the beneficiary address.
    /// @return Address of the beneficiary.
    function beneficiary() external view returns (address);

    ///
    /// EVENTS:
    ///

    /// @notice Emitted when the beneficiary is changed by the owner.
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);

    /// @notice Emitted when the collector contract receives ETH.
    event Collected(address sender, uint256 amount);

    /// @notice Emitted when the collected ETH was withdrawn.
    event Withdrawn(address beneficiary, uint256 amount);

    /// @notice Emitted when the collected tokens were withdrawn.
    event WithdrawnTokens(address indexed token, address beneficiary, uint256 amount);
}