// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A smart contract for registering vaults for payments.
interface IFeeCollector {
    struct Vault {
        address owner;
        address token;
        bool multiplePayments;
        uint120 fee;
        uint128 collected;
        mapping(address => bool) paid;
    }

    /// @notice Registers a vault and it's fee.
    /// @param owner The address that receives the fees from the payment.
    /// @param token The zero address for Ether, otherwise an ERC20 token.
    /// @param multiplePayments Whether the fee can be paid multiple times.
    /// @param fee The amount of fee to pay in base units.
    function registerVault(address owner, address token, bool multiplePayments, uint120 fee) external;

    /// @notice Registers the paid fee, both in Ether or ERC20.
    /// @param vaultId The id of the vault to pay to.
    function payFee(uint256 vaultId) external payable;

    /// @notice Sets the address that receives Guild's share from the funds.
    /// @dev Callable only by the current Guild fee collector.
    /// @param newFeeCollector The new address of guildFeeCollector.
    function setGuildFeeCollector(address payable newFeeCollector) external;

    /// @notice Sets Guild's share from the funds.
    /// @dev Callable only by the Guild fee collector.
    /// @param newShare The percentual value expressed in basis points.
    function setGuildShareBps(uint96 newShare) external;

    /// @notice Changes the details of a vault.
    /// @dev Callable only by the owner of the vault to be changed.
    /// @param vaultId The id of the vault whose details should be changed.
    /// @param newOwner The address that will receive the fees from now on.
    /// @param newMultiplePayments Whether the fee can be paid multiple times from now on.
    /// @param newFee The amount of fee to pay in base units from now on.
    function setVaultDetails(uint256 vaultId, address newOwner, bool newMultiplePayments, uint120 newFee) external;

    /// @notice Distributes the funds from a vault to the fee collectors and the owner.
    /// @param vaultId The id of the vault whose funds should be distributed.
    function withdraw(uint256 vaultId) external;

    /// @notice Returns a vault's details.
    /// @param vaultId The id of the queried vault.
    /// @return owner The owner of the vault who recieves the funds.
    /// @return token The address of the token to receive funds in (the zero address in case of Ether).
    /// @return multiplePayments Whether the fee can be paid multiple times.
    /// @return fee The amount of required funds in base units.
    /// @return collected The amount of already collected funds.
    function getVault(
        uint256 vaultId
    ) external view returns (address owner, address token, bool multiplePayments, uint120 fee, uint128 collected);

    /// @notice Returns if an account has paid the fee to a vault.
    /// @param vaultId The id of the queried vault.
    /// @param account The address of the queried account.
    function hasPaid(uint256 vaultId, address account) external view returns (bool paid);

    /// @notice Returns the address that receives Guild's share from the funds.
    function guildFeeCollector() external view returns (address payable);

    /// @notice Returns the percentage of Guild's share expressed in basis points.
    function guildShareBps() external view returns (uint96);

    /// @notice Event emitted when a call to {payFee} succeeds.
    /// @param vaultId The id of the vault that received the payment.
    /// @param account The address of the account that paid.
    /// @param amount The amount of fee received in base units.
    event FeeReceived(uint256 indexed vaultId, address indexed account, uint256 amount);

    /// @notice Event emitted when the Guild fee collector address is changed.
    /// @param newFeeCollector The address to change guildFeeCollector to.
    event GuildFeeCollectorChanged(address newFeeCollector);

    /// @notice Event emitted when the share of the Guild fee collector changes.
    /// @param newShare The new value of guildShareBps.
    event GuildShareBpsChanged(uint96 newShare);

    /// @notice Event emitted when a vault's details are changed.
    /// @param vaultId The id of the altered vault.
    event VaultDetailsChanged(uint256 vaultId);

    /// @notice Event emitted when a new vault is registered.
    /// @param owner The address that receives the fees from the payment.
    /// @param token The zero address for Ether, otherwise an ERC20 token.
    /// @param fee The amount of fee to pay in base units.
    event VaultRegistered(uint256 vaultId, address indexed owner, address indexed token, uint256 fee);

    /// @notice Event emitted when funds are withdrawn by a vault owner.
    /// @param vaultId The id of the vault.
    /// @param guildAmount The amount received by the Guild fee collector in base units.
    /// @param ownerAmount The amount received by the vault's owner in base units.
    event Withdrawn(uint256 indexed vaultId, uint256 guildAmount, uint256 ownerAmount);

    /// @notice Error thrown when multiple payments aren't enabled, but the sender attempts to pay repeatedly.
    /// @param vaultId The id of the vault.
    /// @param sender The sender of the transaction.
    error AlreadyPaid(uint256 vaultId, address sender);

    /// @notice Error thrown when an incorrect amount of fee is attempted to be paid.
    /// @dev requiredAmount might be 0 in cases when an ERC20 payment was expected but Ether was received, too.
    /// @param vaultId The id of the vault.
    /// @param paid The amount of funds received.
    /// @param requiredAmount The amount of fees required by the vault.
    error IncorrectFee(uint256 vaultId, uint256 paid, uint256 requiredAmount);

    /// @notice Error thrown when a function is attempted to be called by the wrong address.
    /// @param sender The address that sent the transaction.
    /// @param owner The address that is allowed to call the function.
    error AccessDenied(address sender, address owner);

    /// @notice Error thrown when an ERC20 transfer failed.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address from, address to);

    /// @notice Error thrown when a vault does not exist.
    /// @param vaultId The id of the requested vault.
    error VaultDoesNotExist(uint256 vaultId);
}