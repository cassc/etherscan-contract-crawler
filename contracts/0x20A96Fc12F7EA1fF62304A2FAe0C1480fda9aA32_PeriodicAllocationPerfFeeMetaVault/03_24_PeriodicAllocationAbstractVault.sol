// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// Libs
import { SameAssetUnderlyingsAbstractVault } from "./SameAssetUnderlyingsAbstractVault.sol";
import { AssetPerShareAbstractVault } from "./AssetPerShareAbstractVault.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { IERC4626Vault } from "../../interfaces/IERC4626Vault.sol";

/**
 * @title   Abstract ERC-4626 vault that periodically invests in underlying ERC-4626 vaults of the same asset.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-27
 */
abstract contract PeriodicAllocationAbstractVault is
    SameAssetUnderlyingsAbstractVault,
    AssetPerShareAbstractVault
{
    // Structure to have settlement data
    struct Settlement {
        uint256 vaultIndex;
        uint256 assets;
    }

    struct AssetSourcingParams {
        /// @notice Shares threshold (basis points) below which assets are sourced from single vault.
        uint32 singleVaultSharesThreshold;
        /// @notice Index of underlying vault in `underlyingVaults` to source small withdrawls from.  Starts from index 0
        uint32 singleSourceVaultIndex;
    }

    /// @notice Basis points calculation scale. 100% = 10000, 1% = 100, 0.01% = 1
    uint256 public constant BASIS_SCALE = 1e4;

    /// @notice Params related to sourcing of assets.
    AssetSourcingParams public sourceParams;

    /// @notice Amount of assets that are transferred from/to the vault.
    uint256 public assetsTransferred;

    /// @notice Threshold amount of transfers to/from for `assetPerShareUpdate`.
    uint256 public assetPerShareUpdateThreshold;

    event SingleVaultSharesThresholdUpdated(uint256 singleVaultSharesThreshold);
    event SingleSourceVaultIndexUpdated(uint32 singleSourceVaultIndex);
    event AssetPerShareUpdateThresholdUpdated(uint256 assetPerShareUpdateThreshold);

    /**
     * @param _underlyingVaults  The underlying vaults address to invest into.
     * @param _sourceParams Params related to sourcing of assets.
     * @param _assetPerShareUpdateThreshold Threshold amount of transfers to/from for `assetPerShareUpdate`.
     */
    function _initialize(
        address[] memory _underlyingVaults,
        AssetSourcingParams memory _sourceParams,
        uint256 _assetPerShareUpdateThreshold
    ) internal virtual {
        require(
            _sourceParams.singleVaultSharesThreshold <= BASIS_SCALE,
            "Invalid shares threshold"
        );
        require(
            _sourceParams.singleSourceVaultIndex < _underlyingVaults.length,
            "Invalid source vault index"
        );

        SameAssetUnderlyingsAbstractVault._initialize(_underlyingVaults);
        AssetPerShareAbstractVault._initialize();

        sourceParams = _sourceParams;
        assetPerShareUpdateThreshold = _assetPerShareUpdateThreshold;
    }

    /**
     * @notice Invests the assets sitting in the vault from previous deposits and mints into the nominated underlying vaults.
     * @param settlements A list of asset amounts and underlying vault indices to deposit the assets sitting in the vault.
     * @dev Provide exact assets amount through settlement and this way remaining assets are left in vault.
     */
    function settle(Settlement[] calldata settlements) external virtual onlyVaultManager {
        Settlement memory settlement;

        for (uint256 i = 0; i < settlements.length; ) {
            settlement = settlements[i];

            if (settlement.assets > 0) {
                // Deposit assets in underlying vault
                resolveVaultIndex(settlement.vaultIndex).deposit(settlement.assets, address(this));
            }

            unchecked {
                ++i;
            }
        }

        // Update assetPerShare
        _updateAssetPerShare();
    }

    /// @dev Calls `_checkAndUpdateAssetPerShare` before abstract `_deposit` logic.
    function _deposit(uint256 assets, address receiver)
        internal
        virtual
        override
        returns (uint256 shares)
    {
        _checkAndUpdateAssetPerShare(assets);
        shares = _previewDeposit(assets);
        _transferAndMint(assets, shares, receiver, true);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _previewDeposit(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, AssetPerShareAbstractVault)
        returns (uint256 shares)
    {
        return AssetPerShareAbstractVault._previewDeposit(assets);
    }

    /// @dev Calls `_checkAndUpdateAssetPerShare` before abstract `_mint` logic.
    function _mint(uint256 shares, address receiver)
        internal
        virtual
        override
        returns (uint256 assets)
    {
        assets = _previewMint(shares);
        _checkAndUpdateAssetPerShare(assets);
        _transferAndMint(assets, shares, receiver, false);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _previewMint(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, AssetPerShareAbstractVault)
        returns (uint256 assets)
    {
        return AssetPerShareAbstractVault._previewMint(shares);
    }

    /// @dev Calls `_checkAndUpdateAssetPerShare` before abstract `_withdraw` logic.
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal virtual override returns (uint256 shares) {
        _checkAndUpdateAssetPerShare(assets);
        shares = _previewWithdraw(assets);

        uint256 availableAssets = _sourceAssets(assets, shares);
        require(availableAssets >= assets, "not enough assets");

        // Burn this vault's shares and transfer the assets to the receiver.
        _burnTransfer(assets, shares, receiver, owner, false);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _previewWithdraw(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, AssetPerShareAbstractVault)
        returns (uint256 shares)
    {
        return AssetPerShareAbstractVault._previewWithdraw(assets);
    }

    /// @dev Calls `_checkAndUpdateAssetPerShare` before abstract `_redeem` logic.
    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual override returns (uint256 assets) {
        assets = _previewRedeem(shares);
        _checkAndUpdateAssetPerShare(assets);

        uint256 availableAssets = _sourceAssets(assets, shares);
        require(availableAssets >= assets, "not enough assets");

        _burnTransfer(assets, shares, receiver, owner, true);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _previewRedeem(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, AssetPerShareAbstractVault)
        returns (uint256 assets)
    {
        return AssetPerShareAbstractVault._previewRedeem(shares);
    }

    /**
     * @notice Sources enough assets from underlying vaults for `redeem` or `withdraw`.
     * @param assets Amount of assets to source from underlying vaults.
     * @param shares Amount of this vault's shares to burn.
     * @return actualAssets Amount of assets sourced to this vault.
     * @dev Ensure there is enough assets in the vault to transfer
     * to the receiver for `withdraw` or `redeem`.
     */
    function _sourceAssets(uint256 assets, uint256 shares) internal returns (uint256 actualAssets) {
        // Get the amount of assets held in this vault.
        actualAssets = _asset.balanceOf(address(this));

        // If there is not enough assets held in this vault, the extra assets need to be sourced from the underlying vaults.
        if (assets > actualAssets) {
            // Bool to track whether sourcing from single vault is successs
            bool sourceFromSingleVaultComplete = false;

            // Calculate how many assets need to be withdrawn from the underlying
            uint256 requiredAssets = assets - actualAssets;

            // Fraction of this vault's shares to be burnt
            uint256 sharesRatio = (shares * BASIS_SCALE) / totalSupply();

            // Load the sourceParams from storage into memory
            AssetSourcingParams memory assetSourcingParams = sourceParams;

            /// Source assets from a single vault
            if (sharesRatio <= assetSourcingParams.singleVaultSharesThreshold) {
                IERC4626Vault underlyingVault = resolveVaultIndex(
                    assetSourcingParams.singleSourceVaultIndex
                );

                // Underlying vault has sufficient assets to cover the sourcing
                if (requiredAssets <= underlyingVault.maxWithdraw(address(this))) {
                    // Withdraw assets
                    underlyingVault.withdraw(requiredAssets, address(this), address(this));
                    sourceFromSingleVaultComplete = true;
                }
            }

            /// Withdraw from all if shareRedeemed are above threshold or sourcing fron single vault was not enough
            if (
                sharesRatio > assetSourcingParams.singleVaultSharesThreshold ||
                !sourceFromSingleVaultComplete
            ) {
                uint256 i;
                uint256 len = _activeUnderlyingVaults.length;
                uint256 totalUnderlyingAssets;

                uint256[] memory underlyingVaultAssets = new uint256[](len);

                // Compute max assets held by each underlying vault and total for the Meta Vault.
                for (i = 0; i < len; ) {
                    underlyingVaultAssets[i] = _activeUnderlyingVaults[i].maxWithdraw(
                        address(this)
                    );
                    // Increment total underlying assets
                    totalUnderlyingAssets += underlyingVaultAssets[i];

                    unchecked {
                        ++i;
                    }
                }

                if (totalUnderlyingAssets >= requiredAssets) {
                    // Amount of assets to be withdrawn from each underlying vault
                    uint256 underlyingAssetsToWithdraw;

                    // For each underlying vault
                    for (i = 0; i < len; ) {
                        if (underlyingVaultAssets[i] > 0) {
                            // source assets proportionally and round up
                            underlyingAssetsToWithdraw =
                                ((requiredAssets * underlyingVaultAssets[i]) /
                                    totalUnderlyingAssets) +
                                1;
                            // check round up is not more than max assets
                            underlyingAssetsToWithdraw = underlyingAssetsToWithdraw >
                                underlyingVaultAssets[i]
                                ? underlyingVaultAssets[i]
                                : underlyingAssetsToWithdraw;

                            // withdraw assets proportionally to this vault
                            _activeUnderlyingVaults[i].withdraw(
                                underlyingAssetsToWithdraw,
                                address(this),
                                address(this)
                            );
                        }
                        unchecked {
                            ++i;
                        }
                    }
                }
            }
            // Update vault actual assets
            actualAssets = _asset.balanceOf(address(this));
        }
    }

    /// @dev Checks whether assetPerShare needs to be updated and updates it.
    /// @param _assets Amount of assets requested for transfer to/from the vault.
    function _checkAndUpdateAssetPerShare(uint256 _assets) internal {
        // 0 threshold means update before each transfer
        if (assetPerShareUpdateThreshold == 0) {
            _updateAssetPerShare();
        } else {
            // if the transferred amount including this transfer is above threshold
            if (assetsTransferred + _assets >= assetPerShareUpdateThreshold) {
                _updateAssetPerShare();

                // reset assetsTransferred
                assetsTransferred = 0;
            } else {
                // increment assetsTransferred
                assetsTransferred += _assets;
            }
        }
    }

    /***************************************
                Vault Properties setters
    ****************************************/

    /// @notice `Governor` sets the threshold for large withdrawals that withdraw proportionally
    /// from all underlying vaults instead of just from a single configured vault.
    /// This means smaller `redeem` and `withdraw` txs pay a lot less gas.
    /// @param _singleVaultSharesThreshold Percentage of shares being redeemed in basis points. eg 20% = 2000, 5% = 500
    function setSingleVaultSharesThreshold(uint32 _singleVaultSharesThreshold)
        external
        onlyGovernor
    {
        require(_singleVaultSharesThreshold <= BASIS_SCALE, "Invalid shares threshold");
        sourceParams.singleVaultSharesThreshold = _singleVaultSharesThreshold;

        emit SingleVaultSharesThresholdUpdated(_singleVaultSharesThreshold);
    }

    /// @notice `Governor` sets the underlying vault that small withdrawals are redeemed from.
    /// @param _singleSourceVaultIndex the underlying vault's index position in `underlyingVaults`. This starts from index 0.
    function setSingleSourceVaultIndex(uint32 _singleSourceVaultIndex) external onlyGovernor {
        // Check the single source vault is active.
        resolveVaultIndex(_singleSourceVaultIndex);
        sourceParams.singleSourceVaultIndex = _singleSourceVaultIndex;

        emit SingleSourceVaultIndexUpdated(_singleSourceVaultIndex);
    }

    /// @notice Governor sets the threshold asset amount of cumulative transfers to/from the vault before the assets per share is updated.
    /// @param _assetPerShareUpdateThreshold cumulative asset transfers amount.
    function setAssetPerShareUpdateThreshold(uint256 _assetPerShareUpdateThreshold)
        external
        onlyGovernor
    {
        assetPerShareUpdateThreshold = _assetPerShareUpdateThreshold;

        emit AssetPerShareUpdateThresholdUpdated(_assetPerShareUpdateThreshold);
    }

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _convertToAssets(uint256 shares)
        internal
        view
        virtual
        override(AssetPerShareAbstractVault, AbstractVault)
        returns (uint256 assets)
    {
        return AssetPerShareAbstractVault._convertToAssets(shares);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _convertToShares(uint256 assets)
        internal
        view
        virtual
        override(AssetPerShareAbstractVault, AbstractVault)
        returns (uint256 shares)
    {
        return AssetPerShareAbstractVault._convertToShares(assets);
    }

    /***************************************
                Internal Hooks
    ****************************************/

    /// @dev Updates assetPerShare after rebalance
    function _afterRebalance() internal virtual override {
        _updateAssetPerShare();
    }

    /// @dev Updates assetPerShare after an underlying vault is removed
    function _afterRemoveVault() internal virtual override {
        _updateAssetPerShare();
    }
}