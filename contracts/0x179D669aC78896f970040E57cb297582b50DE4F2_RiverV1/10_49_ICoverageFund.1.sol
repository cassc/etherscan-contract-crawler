//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Coverage Fund Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to receive donations for the slashing coverage fund and pull the funds into river
interface ICoverageFundV1 {
    /// @notice The storage river address has changed
    /// @param river The new river address
    event SetRiver(address indexed river);

    /// @notice A donation has been made to the coverage fund
    /// @param donator Address that performed the donation
    /// @param amount The amount donated
    event Donate(address indexed donator, uint256 amount);

    /// @notice The fallback or receive callback has been triggered
    error InvalidCall();

    /// @notice A donation with 0 ETH has been performed
    error EmptyDonation();

    /// @notice Initialize the coverage fund with the required arguments
    /// @param _riverAddress Address of River
    function initCoverageFundV1(address _riverAddress) external;

    /// @notice Pulls ETH into the River contract
    /// @dev Only callable by the River contract
    /// @param _maxAmount The maximum amount to pull into the system
    function pullCoverageFunds(uint256 _maxAmount) external;

    /// @notice Donates ETH to the coverage fund contract
    function donate() external payable;

    /// @notice Ether receiver
    receive() external payable;

    /// @notice Invalid fallback detector
    fallback() external payable;
}