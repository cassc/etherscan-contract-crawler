// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A smart contract for registering vaults for payments.
interface IFeeCollector {
    /// @notice An item that represents whom to transfer fees to and what percentage of the fees
    /// should be sent (expressed in basis points).
    struct FeeShare {
        address payable treasury;
        uint96 feeShareBps;
    }

    /// @notice Contains information about individual fee collections.
    /// @dev See {getVault} for details.
    struct Vault {
        address payable owner;
        address token;
        bool multiplePayments;
        uint128 fee;
        uint128 balance;
        mapping(address => bool) paid;
    }

    /// @notice Registers a vault and it's fee.
    /// @param owner The address that receives the fees from the payment.
    /// @param token The zero address for Ether, otherwise an ERC20 token.
    /// @param multiplePayments Whether the fee can be paid multiple times.
    /// @param fee The amount of fee to pay in base units.
    function registerVault(address payable owner, address token, bool multiplePayments, uint128 fee) external;

    /// @notice Registers the paid fee, both in Ether or ERC20.
    /// @dev If ERC20 tokens are used, the contract needs to be approved using the {IERC20-approve} function.
    /// @param vaultId The id of the vault to pay to.
    function payFee(uint256 vaultId) external payable;

    /// @notice Distributes the funds from a vault to the fee collectors and the owner.
    /// @dev Callable only by the vault's owner.
    /// @param vaultId The id of the vault whose funds should be distributed.
    /// @param feeSchemaKey The key of the schema used to distribute fees.
    function withdraw(uint256 vaultId, string calldata feeSchemaKey) external;

    /// @notice Adds a new fee schema (array of FeeShares).
    /// Note that any remaining percentage of the fees will go to Guild's treasury.
    /// A FeeShare is an item that represents whom to transfer fees to and what percentage of the fees
    /// should be sent (expressed in basis points).
    /// @dev Callable only by the owner.
    /// @param key The key of the schema, used to look it up in the feeSchemas mapping.
    /// @param feeShares An array of FeeShare structs.
    function addFeeSchema(string calldata key, FeeShare[] calldata feeShares) external;

    /// @notice Sets the address that receives Guild's share from the funds.
    /// @dev Callable only by the owner.
    /// @param newTreasury The new address of Guild's treasury.
    function setGuildTreasury(address payable newTreasury) external;

    /// @notice Sets Guild's and any partner's share from the funds.
    /// @dev Callable only by the owner.
    /// @param newShare The percentual value expressed in basis points.
    function setTotalFeeBps(uint96 newShare) external;

    /// @notice Changes the details of a vault.
    /// @dev Callable only by the owner of the vault to be changed.
    /// @param vaultId The id of the vault whose details should be changed.
    /// @param newOwner The address that will receive the fees from now on.
    /// @param newMultiplePayments Whether the fee can be paid multiple times from now on.
    /// @param newFee The amount of fee to pay in base units from now on.
    function setVaultDetails(
        uint256 vaultId,
        address payable newOwner,
        bool newMultiplePayments,
        uint128 newFee
    ) external;

    /// @notice Returns a fee schema for a given key.
    /// @param key The key of the schema.
    /// @param schema The fee schema corresponding to the key.
    function getFeeSchema(string calldata key) external view returns (FeeShare[] memory schema);

    /// @notice Returns a vault's details.
    /// @param vaultId The id of the queried vault.
    /// @return owner The owner of the vault who recieves the funds.
    /// @return token The address of the token to receive funds in (the zero address in case of Ether).
    /// @return multiplePayments Whether the fee can be paid multiple times.
    /// @return fee The amount of required funds in base units.
    /// @return balance The amount of already collected funds.
    function getVault(
        uint256 vaultId
    ) external view returns (address payable owner, address token, bool multiplePayments, uint128 fee, uint128 balance);

    /// @notice Returns if an account has paid the fee to a vault.
    /// @param vaultId The id of the queried vault.
    /// @param account The address of the queried account.
    function hasPaid(uint256 vaultId, address account) external view returns (bool paid);

    /// @notice Returns the address that receives Guild's share from the funds.
    function guildTreasury() external view returns (address payable);

    /// @notice Returns the percentage of Guild's and any partner's share expressed in basis points.
    function totalFeeBps() external view returns (uint96);

    /// @notice Event emitted when a call to {payFee} succeeds.
    /// @param vaultId The id of the vault that received the payment.
    /// @param account The address of the account that paid.
    /// @param amount The amount of fee received in base units.
    event FeeReceived(uint256 indexed vaultId, address indexed account, uint256 amount);

    /// @notice Event emitted when a new fee schema is added.
    /// @param key The key of the schema, used to look it up in the feeSchemas mapping.
    event FeeSchemaAdded(string key);

    /// @notice Event emitted when the Guild treasury address is changed.
    /// @param newTreasury The address to change Guild's treasury to.
    event GuildTreasuryChanged(address newTreasury);

    /// @notice Event emitted when the share of the total fee changes.
    /// @param newShare The new value of totalFeeBps.
    event TotalFeeBpsChanged(uint96 newShare);

    /// @notice Event emitted when a vault's details are changed.
    /// @param vaultId The id of the altered vault.
    event VaultDetailsChanged(uint256 vaultId);

    /// @notice Event emitted when a new vault is registered.
    /// @param owner The address that receives the fees from the payment.
    /// @param token The zero address for Ether, otherwise an ERC20 token.
    /// @param fee The amount of fee to pay in base units.
    event VaultRegistered(uint256 vaultId, address payable indexed owner, address indexed token, uint256 fee);

    /// @notice Event emitted when funds are withdrawn by a vault owner.
    /// @param vaultId The id of the vault.
    event Withdrawn(uint256 indexed vaultId);

    /// @notice Error thrown when a function is attempted to be called by the wrong address.
    /// @param sender The address that sent the transaction.
    /// @param owner The address that is allowed to call the function.
    error AccessDenied(address sender, address owner);

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

    /// @notice Error thrown when a vault does not exist.
    /// @param vaultId The id of the requested vault.
    error VaultDoesNotExist(uint256 vaultId);
}