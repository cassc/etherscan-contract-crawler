// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

//Libs
import { PeriodicAllocationAbstractVault } from "../allocate/PeriodicAllocationAbstractVault.sol";
import { PerfFeeAbstractVault } from "../fee/PerfFeeAbstractVault.sol";
import { FeeAdminAbstractVault } from "../fee/FeeAdminAbstractVault.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { VaultManagerRole } from "../../shared/VaultManagerRole.sol";
import { InitializableToken } from "../../tokens/InitializableToken.sol";

/**
 * @notice  EIP-4626 vault that periodically invests 3CRV in the underlying vaults and charge performance fees
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-27
 */
contract PeriodicAllocationPerfFeeMetaVault is
    PeriodicAllocationAbstractVault,
    PerfFeeAbstractVault,
    Initializable
{
    /// @param _nexus Address of the Nexus contract that resolves protocol modules and roles.
    /// @param _asset Address of the vault's underlying asset which is one of DAI/USDC/USDT
    constructor(address _nexus, address _asset) AbstractVault(_asset) VaultManagerRole(_nexus) {}

    /// @notice have to override this function
    /// @dev dummy function
    function _initialize(address dummy)
        internal
        virtual
        override(FeeAdminAbstractVault, VaultManagerRole)
    {}

    /**
     * @param _name  Name of Vault token
     * @param _symbol Symbol of vault token
     * @param _vaultManager Trusted account that can perform vault operations. eg rebalance.
     * @param _performanceFee  Performance fee to be charged
     * @param _feeReceiver  Account that receives fees in the form of vault shares.
     * @param _underlyingVaults  The underlying vaults address to invest into.
     * @param _sourceParams Params related to sourcing of assets
     * @param _assetPerShareUpdateThreshold threshold amount of transfers to/from for assetPerShareUpdate
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _vaultManager,
        uint256 _performanceFee,
        address _feeReceiver,
        address[] memory _underlyingVaults,
        AssetSourcingParams memory _sourceParams,
        uint256 _assetPerShareUpdateThreshold
    ) external initializer {
        // Set the vault's decimals to the same as the reference asset.
        uint8 decimals_ = InitializableToken(address(_asset)).decimals();
        InitializableToken._initialize(_name, _symbol, decimals_);

        // Initialize contracts
        VaultManagerRole._initialize(_vaultManager);
        PerfFeeAbstractVault._initialize(_performanceFee);
        PeriodicAllocationAbstractVault._initialize(
            _underlyingVaults,
            _sourceParams,
            _assetPerShareUpdateThreshold
        );
        FeeAdminAbstractVault._initialize(_feeReceiver);
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/MINT
    //////////////////////////////////////////////////////////////*/

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _deposit(uint256 assets, address receiver)
        internal
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._deposit(assets, receiver);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _previewDeposit(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._previewDeposit(assets);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _mint(uint256 shares, address receiver)
        internal
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._mint(shares, receiver);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _previewMint(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._previewMint(shares);
    }

    /*///////////////////////////////////////////////////////////////
                        WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        internal
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._withdraw(assets, receiver, owner);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _previewWithdraw(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._previewWithdraw(assets);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        internal
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._redeem(shares, receiver, owner);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _previewRedeem(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._previewRedeem(shares);
    }

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _convertToAssets(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._convertToAssets(shares);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _convertToShares(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._convertToShares(assets);
    }

    /***************************************
                Vault Hooks
    ****************************************/

    function _afterDepositHook(
        uint256 assets,
        uint256,
        address,
        bool
    ) internal virtual override {
        // Assets are held in the vault after deposit and mint so this hook is not needed.
        // Assets are deposited using the `settle` function to the underlying
    }

    function _beforeWithdrawHook(
        uint256 assets,
        uint256,
        address,
        bool
    ) internal virtual override {
        // Assets are withdrawn from the underlying using the `sourceAssets` function if there are not enough assets in this vault.
    }

    /***************************************
                Internal Hooks
    ****************************************/

    /// @dev update assetPerShare after charging performance fees
    function _afterChargePerformanceFee() internal virtual override {
        _updateAssetPerShare();
    }
}