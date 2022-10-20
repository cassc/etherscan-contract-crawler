// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Libs
import { SingleSlotMapper } from "../../shared/SingleSlotMapper.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { IERC4626Vault } from "../../interfaces/IERC4626Vault.sol";

/**
 * @title   Abstract ERC-4626 vault that invests in underlying ERC-4626 vaults of the same asset.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-03-28
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(_nexus)
 * - LightAbstractVault(_assetArg)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - InitializableToken._initialize(_name, _symbol, decimals)
 * - VaultManagerRole._initialize(_vaultManager)
 * - SameAssetUnderlyingsAbstractVault._initialize(_underlyingVaults)
 */
abstract contract SameAssetUnderlyingsAbstractVault is AbstractVault {
    using SafeERC20 for IERC20;
    using SingleSlotMapper for uint256;

    struct Swap {
        uint256 fromVaultIndex;
        uint256 toVaultIndex;
        uint256 shares;
        uint256 assets;
    }

    /// @dev List of active underlying vaults this vault invests into.
    IERC4626Vault[] internal _activeUnderlyingVaults;
    /// @dev bit map of external vault indexes to active underlying vault indexes.
    /// This bit map only uses one slot read.
    ///
    /// The first byte from the left is the total number of vaults that have been used.
    /// If a new vault is added, the total number of vaults will be it's vault index.
    ///
    /// There are 62, 4 bit numbers going from right to left that hold the index to the internal
    /// active underlying vaults. This is 62 * 4 = 248 bits.
    /// 248 bits plus the 1 byte (8 bits) for the number of vaults gives 256 bits in the slot.
    /// By default, all external vault indexes are mapped to 0xF (15) which is an invalid index.
    /// When a vault is removed, it's mapped active underlying vault index is set back to 0xF.
    /// This means there is a maximum of 15 active underlying vaults.
    /// There is also a limit of 62 vaults that can be used over the life of this vault.
    uint256 internal vaultIndexMap;

    event AddedVault(uint256 indexed vaultIndex, address indexed vault);
    event RemovedVault(uint256 indexed vaultIndex, address indexed vault);

    /**
     * @param _underlyingVaults  The underlying vaults address to invest into.
     */
    function _initialize(address[] memory _underlyingVaults) internal virtual {
        uint256 vaultsLen = _underlyingVaults.length;
        require(vaultsLen > 0, "No underlying vaults");

        // Initialised all 62 vault indexes to 0xF which is an invalid underlying vault index.
        // The last byte (8 bits) from the left is reserved for the number of vault indexes that have been issued
        /// which is initialized to 0 hence there is 62 and not 64 Fs.
        uint256 vaultIndexMapMem = SingleSlotMapper.initialize();

        // For each underlying vault
        for (uint256 i = 0; i < vaultsLen; ) {
            vaultIndexMapMem = _addVault(_underlyingVaults[i], vaultIndexMapMem);
            unchecked {
                ++i;
            }
        }
        // Store the vaultIndexMap in storage
        vaultIndexMap = vaultIndexMapMem;
    }

    /**
     * @notice Includes all the assets in this vault plus all the underlying vaults.
     * The amount of assets in each underlying vault is calculated using the vault's share of the
     * underlying vault's total assets. `totalAssets()` does not account for fees or slippage so
     * the actual asset value is likely to be less.
     *
     * @return  totalManagedAssets The total assets managed by this vault.
     */
    function totalAssets() public view virtual override returns (uint256 totalManagedAssets) {
        totalManagedAssets = _asset.balanceOf(address(this)) + _totalUnderlyingAssets();
    }

    /**
     * @notice Includes the assets in all underlying vaults. It does not include the assets in this vault.
     * @return  totalUnderlyingAssets The total assets held in underlying vaults
     */
    function _totalUnderlyingAssets() internal view returns (uint256 totalUnderlyingAssets) {
        // Get the assets held by this vault in each of in the active underlying vaults
        uint256 len = _activeUnderlyingVaults.length;

        for (uint256 i = 0; i < len; ) {
            totalUnderlyingAssets += _activeUnderlyingVaults[i].maxWithdraw(address(this));
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the active number of underlying vaults.
     * This excludes any vaults that have been removed.
     *
     * @return  activeVaults The number of active underlying vaults.
     */
    function activeUnderlyingVaults() external view virtual returns (uint256 activeVaults) {
        activeVaults = _activeUnderlyingVaults.length;
    }

    /**
     * @notice Returns the total number of underlying vaults, both active and inactive.
     * The next vault added will have a vault index of this value.
     *
     * @return  totalVaults The number of active and inactive underlying vaults.
     */
    function totalUnderlyingVaults() external view virtual returns (uint256 totalVaults) {
        totalVaults = vaultIndexMap.indexes();
    }

    /**
     * @notice Resolves a vault index to an active underlying vault address.
     * This only works for active vaults.
     * A `Inactive vault` error will be thrown if the vault index has not been used
     * or the underlying vault is now inactive.s
     *
     * @param   vaultIndex External vault index used to identify the underlying vault.
     * @return  vault Address of the underlying vault.
     */
    function resolveVaultIndex(uint256 vaultIndex)
        public
        view
        virtual
        returns (IERC4626Vault vault)
    {
        // resolve the external vault index to the internal underlying vaults
        uint256 activeUnderlyingVaultsIndex = vaultIndexMap.map(vaultIndex);
        require(activeUnderlyingVaultsIndex < 0xF, "Inactive vault");
        vault = _activeUnderlyingVaults[activeUnderlyingVaultsIndex];
    }

    /**
     * @notice `VaultManager` rebalances the assets in the underlying vaults.
     * This can be moving assets between underlying vaults, moving assets in underlying
     * vaults back to this vault, or moving assets in this vault to underlying vaults.
     */
    function rebalance(Swap[] calldata swaps) external virtual onlyVaultManager {
        // For each swap
        Swap memory swap;
        uint256 vaultIndexMapMem = vaultIndexMap;
        uint256 fromVaultIndex;
        uint256 toVaultIndex;
        for (uint256 i = 0; i < swaps.length; ) {
            swap = swaps[i];

            // Map the external vault index to the internal active underlying vaults.
            fromVaultIndex = vaultIndexMapMem.map(swap.fromVaultIndex);
            require(fromVaultIndex < 0xF, "Inactive from vault");
            toVaultIndex = vaultIndexMapMem.map(swap.toVaultIndex);
            require(toVaultIndex < 0xF, "Inactive to vault");

            if (swap.assets > 0) {
                // Withdraw assets from underlying vault
                _activeUnderlyingVaults[fromVaultIndex].withdraw(
                    swap.assets,
                    address(this),
                    address(this)
                );

                // Deposits withdrawn assets in underlying vault
                _activeUnderlyingVaults[toVaultIndex].deposit(swap.assets, address(this));
            }
            if (swap.shares > 0) {
                // Redeem shares from underlying vault
                uint256 redeemedAssets = _activeUnderlyingVaults[fromVaultIndex].redeem(
                    swap.shares,
                    address(this),
                    address(this)
                );

                // Deposits withdrawn assets in underlying vault
                _activeUnderlyingVaults[toVaultIndex].deposit(redeemedAssets, address(this));
            }

            unchecked {
                ++i;
            }
        }

        // Call _afterRebalance hook
        _afterRebalance();
    }

    /***************************************
                Vault Management
    ****************************************/

    /**
     * @notice  Adds a new underlying ERC-4626 compliant vault.
     * This Meta Vault approves the new underlying vault to transfer max assets.
     * There is a limit of 15 active underlying vaults. If more vaults are needed,
     * another active vaults will need to be removed first.
     * There is also a limit of 62 underlying vaults that can be used by this Meta Vault
     * over its lifetime. That's both active and inactive vaults.
     *
     * @param _underlyingVault Address of a ERC-4626 compliant vault.
     */
    function addVault(address _underlyingVault) external onlyGovernor {
        vaultIndexMap = _addVault(_underlyingVault, vaultIndexMap);
    }

    /**
     * @param _underlyingVault Address of the new underlying vault.
     * @param _vaultIndexMap   The map of external to internal vault indexes.
     * @return vaultIndexMap_  The updated map of vault indexes.
     */
    function _addVault(address _underlyingVault, uint256 _vaultIndexMap)
        internal
        virtual
        returns (uint256 vaultIndexMap_)
    {
        require(IERC4626Vault(_underlyingVault).asset() == address(_asset), "Invalid vault asset");

        // Store new underlying vault in the contract.
        _activeUnderlyingVaults.push(IERC4626Vault(_underlyingVault));

        // Map the external vault index to the index of the internal active underlying vaults.
        uint256 vaultIndex;
        (vaultIndexMap_, vaultIndex) = _vaultIndexMap.addValue(_activeUnderlyingVaults.length - 1);

        // Approve the underlying vaults to transfer assets from this Meta Vault.
        _asset.safeApprove(_underlyingVault, type(uint256).max);

        emit AddedVault(vaultIndex, _underlyingVault);
    }

    /**
     * @notice  Removes an underlying ERC-4626 compliant vault.
     * All underlying shares are redeemed with the assets transferred to this vault.
     *
     * @param vaultIndex Index of the underlying vault starting from 0.
     */
    function removeVault(uint256 vaultIndex) external onlyGovernor {
        uint256 newUnderlyingVaultsLen = _activeUnderlyingVaults.length - 1;
        require(vaultIndex <= newUnderlyingVaultsLen, "Invalid from vault index");

        // Resolve the external vault index to the index in the internal active underlying vaults.
        uint256 vaultIndexMapMem = vaultIndexMap;
        uint256 underlyingVaultIndex = vaultIndexMapMem.map(vaultIndex);
        require(underlyingVaultIndex < 0xF, "Inactive vault");

        // Withdraw all assets from the underlying vault being removed.
        uint256 underlyingShares = _activeUnderlyingVaults[underlyingVaultIndex].maxRedeem(
            address(this)
        );
        if (underlyingShares > 0) {
            _activeUnderlyingVaults[vaultIndex].redeem(
                underlyingShares,
                address(this),
                address(this)
            );
        }

        address underlyingVault = address(_activeUnderlyingVaults[underlyingVaultIndex]);

        // move all vaults to the left after the vault being removed
        for (uint256 i = underlyingVaultIndex; i < newUnderlyingVaultsLen; ) {
            _activeUnderlyingVaults[i] = _activeUnderlyingVaults[i + 1];
            unchecked {
                ++i;
            }
        }
        _activeUnderlyingVaults.pop(); // delete the last underlying vault

        // Remove the underlying vault from the vault index map.
        vaultIndexMap = vaultIndexMapMem.removeValue(underlyingVaultIndex);

        emit RemovedVault(vaultIndex, underlyingVault);
    }

    /***************************************
                Internal Hooks
    ****************************************/

    /**
     * @dev Optional hook to do something after rebalance.
     * For example, assetsPerShare update after rebalance by PeriodicAllocationAbstractVault
     */
    function _afterRebalance() internal virtual {}
}