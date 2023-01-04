// SPDX-License-Identifier: None
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title MetaWealth Asset Fractionalizer Contract
/// @author Ghulam Haider
/// @notice Prefer deploying this contract through FractionalizerFactory
interface IAssetVault {
    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account, uint256 shares);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    /// @notice Fires when trading currency for an asset is changed
    /// @param oldCurrency is the previously-used currency
    /// @param newCurrency is the new currency added
    event CurrencyChanged(address oldCurrency, address newCurrency);

    /// @notice Emits when the trading is enabled/disabled for the asset
    /// @param trading is the boolean representing the new state of trading
    event StatusChanged(bool trading);

    /// @notice Emits when funcds are deposited and distributed to the users
    /// @param currency is the token that the funds were paid in
    /// @param amount is the amount distributed to the holders
    event FundsDeposited(address currency, uint256 amount);

    /// @notice For cross-contract operability, returns the read-only parameters
    /// @return active_ is the trade activity status of asset
    function isActive() external view returns (bool active_);

    /// @notice Gets the list of addresses that own part of the asset
    /// @return shareholders is the array containing addresses
    function getShareholders()
        external
        view
        returns (address[] memory shareholders);

    /// @notice Returns the asset's current trading currency
    /// @return currency is the currency the asset is being traded at
    function getTradingCurrency() external view returns (address currency);

    /// @notice Changes the asset's trading currency to a new one
    /// @param newCurrency is the currency to change to
    function setTradingCurrency(IERC20Upgradeable newCurrency) external;

    /// @notice Toggles between active/inactive status for this asset
    /// @notice If inactive, no trades can occur for this asset
    /// @return newStatus is the active/inactive state after execution of this function
    function toggleStatus() external returns (bool newStatus);

    /// @notice Burns all shares from owner's balance
    /// @dev only the moderator admin or VaultBuilder through defractianalise metod can burn, and if this account owns all shares
    function defractionalize() external returns (address shareholder);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}