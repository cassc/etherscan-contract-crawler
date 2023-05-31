// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/vault/IVaultImmutable.sol";
import "../interfaces/vault/IVaultDetails.sol";
import "../external/@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "../external/@openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @notice This contract implements a proxy that is upgradeable by an admin.
 */
contract VaultTransparentUpgradeableProxy is TransparentUpgradeableProxy, IVaultImmutable {
    /// @notice Vault underlying asset
    IERC20 public override immutable underlying;

    /// @notice Vault risk provider address
    address public override immutable riskProvider;

    /// @notice A number from -10 to 10 indicating the risk tolerance of the vault
    int8 public override immutable riskTolerance;

    /**
     * @notice Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`.
     */
    constructor(
        address _logic,
        address admin_,
        VaultImmutables memory vaultImmutables
    ) TransparentUpgradeableProxy(_logic, admin_, "") payable {
        underlying = vaultImmutables.underlying;
        riskProvider = vaultImmutables.riskProvider;
        riskTolerance = vaultImmutables.riskTolerance;
    }
}