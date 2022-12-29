// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "SafeERC20.sol";

interface IVaultAPI is IERC20 {
    function deposit(uint256 _amount, address recipient)
        external
        returns (uint256 shares);

    function withdraw(uint256 _shares) external;

    function token() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes calldata signature
    ) external returns (bool);
}

interface IRegistry {
    function latestVault(address token) external view returns (address);
}

/**
 * @title Yearn Simple Vault Migrator
 * @author yearn
 * @notice This contract is used to migrate from an older to a newer version of a yearn vault.
 * @dev Contract can only migrate to the newest version of a vault for a token. Migration
 *  must be between vaults that have the same underlying token. Gasless approval via permit()
 *  is an option for all v2 yearn vault API versions except 0.4.4.
 */
contract SimpleVaultMigrator {
    using SafeERC20 for IERC20;
    using SafeERC20 for IVaultAPI;

    /* ========== STATE VARIABLES ========== */

    /// @notice Governance can update the registry and sweep stuck tokens.
    address public governance;

    /// @notice New address must be set by current gov and then accepted to transfer power.
    address public pendingGovernance;

    /// @notice Vault registry to pull info about yearn vaults. This will vary based on network.
    address public registry;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _governance, address _registry) {
        require(_governance != address(0), "Governance cannot be 0");
        require(_registry != address(0), "Registry cannot be 0");
        governance = _governance;

        registry = _registry;
    }

    /* ========== EVENTS ========== */
    event NewGovernance(address indexed governance);

    event NewRegistry(address indexed registry);

    event SuccessfulMigration(
        address indexed user,
        address indexed vaultFrom,
        address indexed vaultTo,
        uint256 migratedAmount
    );

    /* ========== MODIFIERS ========== */
    modifier onlyGovernance {
        require(msg.sender == governance, "Sender must be governance");
        _;
    }

    modifier onlyPendingGovernance {
        require(
            msg.sender == pendingGovernance,
            "Sender must be pending governance"
        );
        _;
    }

    modifier checkVaults(address vaultFrom, address vaultTo) {
        require(
            IVaultAPI(vaultFrom).token() == IVaultAPI(vaultTo).token(),
            "Vaults must have the same token"
        );
        require(
            IRegistry(registry).latestVault(IVaultAPI(vaultFrom).token()) ==
                vaultTo,
            "Target vault should be the latest for token"
        );
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Migrate all of our vault shares to the newest vault version.
     * @dev Throws if the vaults do not have the same want, or if our
     *  target is not the newest version
     * @param vaultFrom The old vault we are migrating from.
     * @param vaultTo The new vault we are migrating to.
     */
    function migrateAll(address vaultFrom, address vaultTo) external {
        uint256 shares = IVaultAPI(vaultFrom).balanceOf(msg.sender);

        _migrate(vaultFrom, vaultTo, shares);
    }

    /**
     * @notice Migrate a specific amount of our vault shares to the newest vault version.
     * @dev Throws if the vaults do not have the same want, or if our
     *  target is not the newest version
     * @param vaultFrom The old vault we are migrating from.
     * @param vaultTo The new vault we are migrating to.
     * @param shares The number of shares to migrate.
     */
    function migrateShares(
        address vaultFrom,
        address vaultTo,
        uint256 shares
    ) external {
        _migrate(vaultFrom, vaultTo, shares);
    }

    function _migrate(
        address vaultFrom,
        address vaultTo,
        uint256 shares
    ) internal checkVaults(vaultFrom, vaultTo) {
        // Transfer in vaultFrom shares
        IVaultAPI vf = IVaultAPI(vaultFrom);

        uint256 preBalanceVaultFrom = vf.balanceOf(address(this));

        vf.safeTransferFrom(msg.sender, address(this), shares);

        uint256 balanceVaultFrom =
            vf.balanceOf(address(this)) - preBalanceVaultFrom;

        // Withdraw token from vaultFrom
        IERC20 token = IERC20(vf.token());

        uint256 preBalanceToken = token.balanceOf(address(this));

        vf.withdraw(balanceVaultFrom);

        uint256 balanceToken = token.balanceOf(address(this)) - preBalanceToken;

        // Deposit new vault
        token.safeIncreaseAllowance(vaultTo, balanceToken);

        IVaultAPI(vaultTo).deposit(balanceToken, msg.sender);
        emit SuccessfulMigration(msg.sender, vaultFrom, vaultTo, shares);
    }

    /**
     * @notice Migrate all of our vault shares to the newest
     *  vault version using the permit function for gasless approvals.
     * @dev Throws if the vaults do not have the same want, or if our
     *  target is not the newest version. Cannot be used with 0.4.4 vaults.
     * @param vaultFrom The old vault we are migrating from.
     * @param vaultTo The new vault we are migrating to.
     * @param deadline The deadline for our permit call.
     * @param signature The signature for our permit call.
     */
    function migrateAllWithPermit(
        address vaultFrom,
        address vaultTo,
        uint256 deadline,
        bytes calldata signature
    ) external {
        uint256 shares = IVaultAPI(vaultFrom).balanceOf(msg.sender);

        _permit(vaultFrom, shares, deadline, signature);
        _migrate(vaultFrom, vaultTo, shares);
    }

    /**
     * @notice Migrate a specific amount of our vault shares to the newest
     *  vault version using the permit function for gasless approvals.
     * @dev Throws if the vaults do not have the same want, or if our
     *  target is not the newest version. Cannot be used with 0.4.4 vaults.
     * @param vaultFrom The old vault we are migrating from.
     * @param vaultTo The new vault we are migrating to.
     * @param shares The number of shares to migrate.
     * @param deadline The deadline for our permit call.
     * @param signature The signature for our permit call.
     */
    function migrateSharesWithPermit(
        address vaultFrom,
        address vaultTo,
        uint256 shares,
        uint256 deadline,
        bytes calldata signature
    ) external {
        _permit(vaultFrom, shares, deadline, signature);
        _migrate(vaultFrom, vaultTo, shares);
    }

    function _permit(
        address vault,
        uint256 value,
        uint256 deadline,
        bytes calldata signature
    ) internal {
        require(
            IVaultAPI(vault).permit(
                msg.sender,
                address(this),
                value,
                deadline,
                signature
            ),
            "Unable to permit on vault"
        );
    }

    /**
     * @notice Sweep out any tokens accidentally sent to this address.
     * @dev Throws if the caller is not current governance.
     * @param _token The token address to sweep out.
     */
    function sweep(address _token) external onlyGovernance {
        IERC20(_token).safeTransfer(
            governance,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /* ========== SETTERS ========== */

    /**
     * @notice Starts the 1st phase of the governance transfer.
     * @dev Throws if the caller is not current governance.
     * @param _pendingGovernance The next governance address.
     */
    function setPendingGovernance(address _pendingGovernance)
        external
        onlyGovernance
    {
        pendingGovernance = _pendingGovernance;
    }

    /**
     * @notice Completes the 2nd phase of the governance transfer.
     * @dev Throws if the caller is not the pending caller.
     *  Emits a NewGovernance event.
     */
    function acceptGovernance() external onlyPendingGovernance {
        governance = msg.sender;
        pendingGovernance = address(0);
        emit NewGovernance(msg.sender);
    }

    /**
     * @notice Sets the address used for our registry.
     * @dev Throws if the caller is not current governance or if using 0 as address.
     * @param _registry The network's vault registry address.
     */
    function setRegistry(address _registry) external onlyGovernance {
        require(_registry != address(0), "Registry cannot be 0");
        registry = _registry;
        emit NewRegistry(_registry);
    }
}