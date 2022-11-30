// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./LoanVault.sol";

/// @title LoanVaultRegistry
/// @dev The LoanVaultRegistry keeps track of deployed LoanVaults.
contract LoanVaultRegistry is OwnableUpgradeable {
    event RegisterLoanVault(string indexed loanVaultId, address indexed loanVault, bool existingVaultReplaced);

    // LoanVault.id() => LoanVault
    mapping(string => address) private loanVaults;

    // Ids of all registered LoanVaults
    string[] private loanVaultIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line

    function initialize() external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    /// @dev Registers a LoanVault by getting its id and putting it into the loanVaults mapping
    /// @param loanVault address of the LoanVault to be registered
    function registerLoanVault(address loanVault) external onlyOwner {
        string memory loanVaultId = LoanVault(loanVault).id();
        emit RegisterLoanVault(loanVaultId, loanVault, loanVaults[loanVaultId] != address(0));

        if (loanVaults[loanVaultId] == address(0)) {
            loanVaultIds.push(loanVaultId);
        }

        loanVaults[loanVaultId] = loanVault;
    }

    /// @dev Returns a LoanVault for a id or reverts if none is found
    /// @param loanVaultId id
    /// @return the LoanVault associated with the id
    function getLoanVault(string calldata loanVaultId) external view returns (address) {
        require(loanVaults[loanVaultId] != address(0), "loanVault not found");
        return loanVaults[loanVaultId];
    }

    /// @dev Returns the ids of all registered LoanVaults
    /// @return ids of all registered LoanVaults
    function getLoanVaultIds() external view returns (string[] memory) {
        return loanVaultIds;
    }
}