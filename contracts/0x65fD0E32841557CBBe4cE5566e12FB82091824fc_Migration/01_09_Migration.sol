// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IConfigurationManager } from "../interfaces/IConfigurationManager.sol";
import { IVault } from "../interfaces/IVault.sol";

/**
 * @title Migration
 * @notice Migration contract that migrates an address position
 * @dev It will withdraw from the old vault and deposit into the new vault
 * @author Pods Finance
 */
contract Migration {
    using SafeERC20 for IERC20;

    IConfigurationManager public immutable configuration;

    error Migration__MigrationNotAllowed();

    constructor(IConfigurationManager _configuration) {
        configuration = _configuration;
    }

    /**
     * @notice migrate liquidity from an old vault to a new vault
     * It will withdraw from the old vault and it will deposit into the new vault
     * @dev The new shares only will be available after the process deposit of the new vault
     * @param from origin vault (old Vault) from the liquidity will be migrated
     * @param shares amount of shares to withdraw from the origin vault (from)
     * @return uint256 shares' amount returned by the new vault contract
     */
    function migrate(IVault from, uint256 shares) external returns (uint256) {
        IVault to = IVault(configuration.getVaultMigration(address(from)));

        if (to == IVault(address(0))) {
            revert Migration__MigrationNotAllowed();
        }

        from.redeem(shares, address(this), msg.sender);

        IERC20 asset = IERC20(from.asset());
        uint256 balance = asset.balanceOf(address(this));
        asset.safeIncreaseAllowance(address(to), balance);
        return to.deposit(balance, msg.sender);
    }

    /**
     * @notice migrateWithPermit liquidity from an old vault to a new vault
     * * It will withdraw from the old vault and it will deposit into the new vault
     * @param from origin vault (old Vault) from where the liquidity will be migrated
     * @param shares amount of shares to withdraw from the origin vault (from)
     * @param deadline deadline that this transaction will be valid
     * @param v recovery id
     * @param r ECDSA signature output
     * @param s ECDSA signature output
     * @return uint256 shares' amount returned by the new vault contract
     */
    function migrateWithPermit(
        IVault from,
        uint256 shares,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        IVault to = IVault(configuration.getVaultMigration(address(from)));

        if (to == IVault(address(0))) {
            revert Migration__MigrationNotAllowed();
        }

        IERC20Permit(address(from)).permit(msg.sender, address(this), shares, deadline, v, r, s);
        from.redeem(shares, address(this), msg.sender);

        IERC20 asset = IERC20(from.asset());
        uint256 balance = asset.balanceOf(address(this));
        asset.safeIncreaseAllowance(address(to), balance);
        return to.deposit(balance, msg.sender);
    }
}