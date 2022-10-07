// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import {ISupplyVault} from "./interfaces/ISupplyVault.sol";

import {SupplyVaultBase} from "./SupplyVaultBase.sol";

/// @title SupplyVault.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice ERC4626-upgradeable Tokenized Vault implementation for Morpho-Aave V2.
contract SupplyVault is ISupplyVault, SupplyVaultBase {
    /// CONSTRUCTOR ///

    /// @dev Initializes network-wide immutables.
    /// @param _morpho The address of the main Morpho contract.
    constructor(address _morpho) SupplyVaultBase(_morpho) {}

    /// INITIALIZER ///

    /// @dev Initializes the vault.
    /// @param _poolToken The address of the pool token corresponding to the market to supply through this vault.
    /// @param _name The name of the ERC20 token associated to this tokenized vault.
    /// @param _symbol The symbol of the ERC20 token associated to this tokenized vault.
    /// @param _initialDeposit The amount of the initial deposit used to prevent pricePerShare manipulation.
    function initialize(
        address _poolToken,
        string calldata _name,
        string calldata _symbol,
        uint256 _initialDeposit
    ) external initializer {
        __SupplyVaultBase_init(_poolToken, _name, _symbol, _initialDeposit);
    }
}