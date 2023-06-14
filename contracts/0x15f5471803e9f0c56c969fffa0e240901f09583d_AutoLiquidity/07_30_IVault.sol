// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "../storage/SmartPoolStorage.sol";
pragma abicoder v2;

/// @title Vault - the vault interface
/// @notice This contract extends ERC20, defines basic vault functions and rewrites ERC20 transferFrom function
interface IVault {

    /// @notice Vault cap
    /// @dev The max number of vault to be issued
    /// @return Max vault cap
    function getCap() external view returns (uint256);

    /// @notice Get fee by type
    /// @dev (0=JOIN_FEE,1=EXIT_FEE,2=MANAGEMENT_FEE,3=PERFORMANCE_FEE,4=TURNOVER_FEE)
    /// @param ft Fee type
    function getFee(SmartPoolStorage.FeeType ft) external view returns (SmartPoolStorage.Fee memory);

    /// @notice Calculate the fee by ratio
    /// @dev This is used to calculate join and redeem fee
    /// @param ft Fee type
    /// @param vaultAmount vault amount
    function calcRatioFee(SmartPoolStorage.FeeType ft, uint256 vaultAmount) external view returns (uint256);


    /// @notice The net worth of the vault from the time the last fee collected
    /// @dev This is used to calculate the performance fee
    /// @param account Account address
    /// @return The net worth of the vault
    function accountNetValue(address account) external view returns (uint256);

    /// @notice The current vault net worth
    /// @dev This is used to update and calculate account net worth
    /// @return The net worth of the vault
    function globalNetValue() external view returns (uint256);

    /// @notice Convert vault amount to cash amount
    /// @dev This converts the user vault amount to cash amount when a user redeems the vault
    /// @param vaultAmount Redeem vault amount
    /// @return Cash amount
    function convertToCash(uint256 vaultAmount) external view returns (uint256);

    /// @notice Convert cash amount to share amount
    /// @dev This converts cash amount to share amount when a user buys the vault
    /// @param cashAmount Join cash amount
    /// @return share amount
    function convertToShare(uint256 cashAmount) external view returns (uint256);

    /// @notice Vault token address for joining and redeeming
    /// @dev This is address is created when the vault is first created.
    /// @return Vault token address
    function ioToken() external view returns (address);

    /// @notice Vault mangement contract address
    /// @dev The vault management contract address is bind to the vault when the vault is created
    /// @return Vault management contract address
    function AM() external view returns (address);

    /// @notice Vault total asset
    /// @dev This calculates vault net worth or AUM
    /// @return Vault total asset
    function assets()external view returns(uint256);

}