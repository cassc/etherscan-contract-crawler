// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title Generic vault interface
/// @author Carter Carlson (@cartercarlson)
interface IVault {
    /// @notice Event of depositing an asset to the vault
    /// @param from            Address which is depositing the asset
    /// @param asset           Address of asset
    /// @param depositAmount   Amount of assets deposited
    /// @param feeAmount       Amount of fees paid
    event HandleDeposit(
        address from,
        address asset,
        uint256 depositAmount,
        uint256 feeAmount
    );

    /// @notice Event of withdrawing an asset from the vault
    /// @param to                  Address which will receive the asset
    /// @param asset               Address of asset
    /// @param withdrawalAmount    Amount of assets withdrawn
    /// @param feeAmount           Amount of fees paid
    event HandleWithdrawal(
        address to,
        address asset,
        uint256 withdrawalAmount,
        uint256 feeAmount
    );

    /// @notice Event of claiming the accrued fees of an asset
    /// @param recipient   Recipient of the asset
    /// @param asset       Address of asset
    /// @param amount      Amount of asset
    event Claim(address recipient, address asset, uint256 amount);

    /// @notice Event of setting the address to receive claimed fees
    /// @param newRecipient New address to receive the claim
    event SetFeeRecipient(address newRecipient);

    /// @notice Claim the accrued fees of an asset
    /// @param asset   Address of asset
    /// @param max     True if claiming all accrued fees of the asset, else false
    /// @param amount  Amount of asset to claim
    function claim(
        address asset,
        bool max,
        uint256 amount
    ) external;

    /// @notice Set the address to receive claimed fees
    /// @param newRecipient New address to receive the claim
    function setFeeRecipient(address newRecipient) external;

    /// @notice Deposit an asset to the vault
    /// @param from            Address which is depositing the asset
    /// @param asset           Address of asset
    /// @param depositAmount   Amount of assets deposited
    /// @param feeAmount       Amount of fees paid
    function handleDeposit(
        address from,
        address asset,
        uint256 depositAmount,
        uint256 feeAmount
    ) external;

    /// @notice Deposit an EIP2612 compliant asset to the vault
    /// @param from            Address which is depositing the asset
    /// @param asset           Address of asset
    /// @param depositAmount   Amount of assets deposited
    /// @param feeAmount       Amount of fees paid
    /// @param deadline  The time at which this expires (unix time)
    /// @param v         v of the signature
    /// @param r         r of the signature
    /// @param s         s of the signature
    function handleDepositWithPermit(
        address from,
        address asset,
        uint256 depositAmount,
        uint256 feeAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Withdraw an asset from the vault
    /// @param to                  Address which will receive the asset
    /// @param asset               Address of asset
    /// @param withdrawalAmount    Amount of assets withdrawn
    function handleWithdrawal(
        address to,
        address asset,
        uint256 withdrawalAmount,
        uint256 feeAmount
    ) external;

    /// @notice View to see if an asset with encoded arguments passed
    ///           when a vault is registered to a new hub
    /// @param encodedArgs  Additional encoded arguments
    /// @return             True if encoded args are valid, else false
    function isValid(bytes memory encodedArgs) external pure returns (bool);
}