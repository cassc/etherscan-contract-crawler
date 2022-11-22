// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// Libs
import { FeeAdminAbstractVault } from "./FeeAdminAbstractVault.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { VaultManagerRole } from "../../shared/VaultManagerRole.sol";

/**
 * @notice   Abstract ERC-4626 vault that calculates a performance fee since the last time the performance fee was charged.
 * @author  mStable
 * @dev     VERSION: 1.1
 *          Created: 2022-05-27
 *          Updated: 2022-11-11
 *
 * The following functions have to be implemented
 * - chargePerformanceFee()
 * - totalAssets()
 * - the token functions on `AbstractToken`.
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - FeeAdminAbstractVault._initialize(_feeReceiver)
 * - PerfFeeAbstractVault._initialize(_performanceFee)
 */
abstract contract PerfFeeAbstractVault is FeeAdminAbstractVault {
    /// @notice Scale of the performance fee. 100% = 1000000, 1% = 10000, 0.01% = 100
    uint256 public constant FEE_SCALE = 1e6;
    /// @notice Scale of the assets per share used to calculate performance fees. 1e26 = 26 decimal places.
    uint256 public constant PERF_ASSETS_PER_SHARE_SCALE = 1e26;

    /// @notice Performance fee scaled to 6 decimal places. 1% = 10000, 0.01% = 100
    uint256 public performanceFee;

    /// @notice Assets per shares used to calculate performance fees scaled to 26 decimal places.
    uint256 public perfFeesAssetPerShare;

    event PerformanceFee(address indexed feeReceiver, uint256 feeShares, uint256 assetsPerShare);
    event PerformanceFeeUpdated(uint256 performanceFee);

    /// @param _performanceFee Performance fee scaled to 6 decimal places.
    function _initialize(uint256 _performanceFee) internal virtual {
        performanceFee = _performanceFee;
        perfFeesAssetPerShare = PERF_ASSETS_PER_SHARE_SCALE;
    }

    /**
     * @dev charges a performance fee since the last time a fee was charged.
     */
    function _chargePerformanceFee() internal {
        //Calculate current assets per share.
        uint256 totalShares = totalSupply();
        uint256 totalAssets = totalAssets();
        uint256 currentAssetsPerShare = totalShares > 0
            ? (totalAssets * PERF_ASSETS_PER_SHARE_SCALE) / totalShares
            : perfFeesAssetPerShare;

        // Only charge a performance fee if assets per share has increased.
        if (currentAssetsPerShare > perfFeesAssetPerShare) {
            // Calculate the amount of shares to mint as a fee.
            // performance fee *
            // total shares *
            // percentrage increase in assets per share
            uint256 feeShares = (performanceFee *
                totalShares *
                (currentAssetsPerShare - perfFeesAssetPerShare)) /
                (perfFeesAssetPerShare * FEE_SCALE);

            // Small gains with a small vault decimals can cause the feeShares to be zero
            // even though there was an increase in the assets per share.
            if (feeShares > 0) {
                _mint(feeReceiver, feeShares);

                // Calculate the new assets per share after fee shares have been minted.
                // The assets per share has reduced as there are now more shares.
                currentAssetsPerShare =  (totalAssets * PERF_ASSETS_PER_SHARE_SCALE) / (totalShares + feeShares);

                emit PerformanceFee(feeReceiver, feeShares, currentAssetsPerShare);
            }
        }

        // Store current assets per share which could be less than the old assets per share.
        perfFeesAssetPerShare = currentAssetsPerShare;

        // Hook for implementing contracts to do something after performance fees have been collected.
        // For example, claim assets from liquidated rewards which will lift the assets per share.
        // New shares will be issued at the now higher assets per share.

        _afterChargePerformanceFee();
    }

    /**
     * @notice Vault Manager charges a performance fee since the last time a fee was charged.
     * As an example, if the assets per share increased by 0.1% in the last week and the performance fee is 4%, the vault shares will be
     * increased by 0.1% * 4% = 0.004% as a fee. If there was 100,000 vault shares, 4 (100,000 * 0.004%) vault shares will be minted as a
     * performance fee. This dilutes the assets per shares of the existing vault shareholders by 0.004%.
     * No performance fee is charged if the assets per share drops.
     * @dev Called from a trusted account so gains and loses can not be gamed.
     */
    function chargePerformanceFee() external virtual onlyVaultManager {
        _chargePerformanceFee();
    }

    /***************************************
            Performance Fee Admin
    ****************************************/

    /**
     * @notice Sets a new performance fee after charging to now using the old performance fee.
     * @param _performanceFee Performance fee scaled to 6 decimal places. 1% = 10000, 0.01% = 100
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyGovernor {
        require(_performanceFee <= FEE_SCALE, "Invalid fee");

        // Charges a performance fee using the old value.
        _chargePerformanceFee();

        // Store the new performance fee.
        performanceFee = _performanceFee;

        emit PerformanceFeeUpdated(_performanceFee);
    }

    /***************************************
            Invest/Divest Assets Hooks
    ****************************************/

    /**
     * @dev Optional hook to do something after performance fees have been collected.
     * For example, claim assets from liquidated rewards which will lift the assets per share.
     * New shares will be issued at the now higher assets per share, but redemptions will use
     * the lower assets per share stored when the performance fee was charged.
     */
    function _afterChargePerformanceFee() internal virtual {}
}