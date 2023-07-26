// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;
pragma abicoder v2;

import './BaseCDPManager.sol';

import '../interfaces/IOracleRegistry.sol';
import '../oracles/KeydonixOracleAbstract.sol';
import '../interfaces/IToken.sol';
import '../interfaces/IVault.sol';
import '../interfaces/ICDPRegistry.sol';
import '../interfaces/vault-managers/parameters/IVaultManagerParameters.sol';
import '../interfaces/IVaultParameters.sol';
import "../interfaces/wrapped-assets/IWrappedAsset.sol";

import '../helpers/ReentrancyGuard.sol';
import '../helpers/SafeMath.sol';

/**
 * @title CDPManager01_Fallback
 **/
contract CDPManager01_Fallback is BaseCDPManager {
    using SafeMath for uint;

    /**
     * @param _vaultManagerParameters The address of the contract with Vault manager parameters
     * @param _oracleRegistry The address of the oracle registry
     * @param _cdpRegistry The address of the CDP registry
     * @param _vaultManagerBorrowFeeParameters The address of the vault manager borrow fee parameters
     **/
    constructor(
        address _vaultManagerParameters,
        address _vaultManagerBorrowFeeParameters,
        address _oracleRegistry,
        address _cdpRegistry,
        address _swappersRegistry
    ) BaseCDPManager(_vaultManagerParameters, _vaultManagerBorrowFeeParameters, _oracleRegistry, _cdpRegistry, _swappersRegistry) {}

    /**
      * @notice Depositing tokens must be pre-approved to Vault address
      * @notice Borrow fee in USDP tokens must be pre-approved to CDP manager address
      * @notice position actually considered as spawned only when debt > 0
      * @dev Deposits collateral and/or borrows USDP
      * @param asset The address of the collateral
      * @param assetAmount The amount of the collateral to deposit
      * @param usdpAmount The amount of USDP token to borrow
      **/
    function join(address asset, uint assetAmount, uint usdpAmount, KeydonixOracleAbstract.ProofDataStruct calldata proofData) public nonReentrant checkpoint(asset, msg.sender) {
        require(usdpAmount != 0 || assetAmount != 0, "Unit Protocol: USELESS_TX");
        require(IToken(asset).decimals() <= 18, "Unit Protocol: NOT_SUPPORTED_DECIMALS");

        if (usdpAmount == 0) {
            vault.depositMain(asset, msg.sender, assetAmount);
        } else {
            if (assetAmount != 0) {
                vault.depositMain(asset, msg.sender, assetAmount);
            }

            _mintUsdp(asset, msg.sender, usdpAmount);
            _ensurePositionCollateralization(asset, msg.sender, proofData);
        }

        // fire an event
        emit Join(asset, msg.sender, assetAmount, usdpAmount);
    }

    /**
     * @notice Deposit asset with leverage. All usdp will be swapped to asset and deposited with user's asset
     * @notice For leverage L user must pass usdpAmount = (L - 1) * assetAmount * price
     * @notice User must:
     * @notice  - preapprove asset to vault: to deposit wrapped asset to vault
     * @notice  - preapprove USDP to swapper: swap USDP to additional asset
     * @notice  - preapprove USDP to CDPManager: to charge borrow (issuance) fee
     * @param asset The address of the collateral
     * @param swapper The address of swapper (for swap usdp->asset)
     * @param assetAmount The amount of the collateral to deposit
     * @param usdpAmount The amount of USDP token to borrow
     * @param minSwappedAssetAmount min asset amount which user must get after swap usdpAmount (in case of slippage)
     */
    function joinWithLeverage(
        address asset,
        ISwapper swapper,
        uint assetAmount,
        uint usdpAmount,
        uint minSwappedAssetAmount,
        KeydonixOracleAbstract.ProofDataStruct calldata proofData
    ) public nonReentrant checkpoint(asset, msg.sender) {
        _joinWithLeverage(
            asset,
            asset,
            false,
            swapper,
            assetAmount,
            usdpAmount,
            minSwappedAssetAmount,
            proofData
        );
    }

    /**
      * @notice Deposit asset, stake it if supported, mint wrapped asset and lock it, borrow USDP
      * @notice User must:
      * @notice  - preapprove token to wrappedAsset: to deposit asset to wrapped asset for wrapping
      * @notice  - preapprove wrapped token to vault: to deposit wrapped asset to vault
      * @notice  - preapprove USDP to CDPManager: to charge borrow (issuance) fee
      * @param wrappedAsset Address of wrapped asset
      * @param assetAmount The amount of the collateral to deposit
      * @param usdpAmount The amount of USDP token to borrow
      **/
    function wrapAndJoin(IWrappedAsset wrappedAsset, uint assetAmount, uint usdpAmount, KeydonixOracleAbstract.ProofDataStruct calldata proofData) external {
        if (assetAmount != 0) {
            wrappedAsset.deposit(msg.sender, assetAmount);
        }

        join(address(wrappedAsset), assetAmount, usdpAmount, proofData);
    }

    /**
     * @notice Wrap and deposit asset with leverage. All usdp will be swapped to asset and deposited with user's asset
     * @notice For leverage L user must pass usdpAmount = (L - 1) * assetAmount * price
     * @notice User must:
     * @notice  - preapprove token to wrappedAsset: to deposit asset to wrapped asset for wrapping
     * @notice  - preapprove wrapped token to vault: to deposit wrapped asset to vault
     * @notice  - preapprove USDP to swapper: swap USDP to additional asset
     * @notice  - preapprove USDP to CDPManager: to charge borrow (issuance) fee
     * @param wrappedAsset The address of wrapped asset
     * @param swapper The address of swapper (for swap usdp->asset)
     * @param assetAmount The amount of the collateral to deposit
     * @param usdpAmount The amount of USDP token to borrow
     * @param minSwappedAssetAmount min asset amount which user must get after swap usdpAmount (in case of slippage)
     */
    function wrapAndJoinWithLeverage(
        IWrappedAsset wrappedAsset,
        ISwapper swapper,
        uint assetAmount,
        uint usdpAmount,
        uint minSwappedAssetAmount,
        KeydonixOracleAbstract.ProofDataStruct calldata proofData
    ) public nonReentrant checkpoint(address(wrappedAsset), msg.sender) {
        _joinWithLeverage(
            address(wrappedAsset),
            address(wrappedAsset.getUnderlyingToken()),
            true,
            swapper,
            assetAmount,
            usdpAmount,
            minSwappedAssetAmount,
            proofData
        );
    }

    /**
      * @notice Tx sender must have a sufficient USDP balance to pay the debt
      * @dev Withdraws collateral and repays specified amount of debt
      * @param asset The address of the collateral
      * @param assetAmount The amount of the collateral to withdraw
      * @param usdpAmount The amount of USDP to repay
      **/
    function exit(address asset, uint assetAmount, uint usdpAmount, KeydonixOracleAbstract.ProofDataStruct calldata proofData) public nonReentrant checkpoint(asset, msg.sender) returns (uint) {

        // check usefulness of tx
        require(assetAmount != 0 || usdpAmount != 0, "Unit Protocol: USELESS_TX");

        uint debt = vault.debts(asset, msg.sender);

        // catch full repayment
        if (usdpAmount > debt) { usdpAmount = debt; }

        if (assetAmount == 0) {
            _repay(asset, msg.sender, usdpAmount);
        } else {
            if (debt == usdpAmount) {
                vault.withdrawMain(asset, msg.sender, assetAmount);
                if (usdpAmount != 0) {
                    _repay(asset, msg.sender, usdpAmount);
                }
            } else {
                _ensureOracle(asset);

                // withdraw collateral to the owner address
                vault.withdrawMain(asset, msg.sender, assetAmount);

                if (usdpAmount != 0) {
                    _repay(asset, msg.sender, usdpAmount);
                }

                vault.update(asset, msg.sender);

                _ensurePositionCollateralization(asset, msg.sender, proofData);
            }
        }

        // fire an event
        emit Exit(asset, msg.sender, assetAmount, usdpAmount);

        return usdpAmount;
    }

    /**
     * @notice Withdraws collateral and repay debt without USDP needed. assetAmountToSwap would be swaped to USDP internally
     * @notice User must:
     * @notice  - preapprove USDP to vault: pay stability fee
     * @notice  - preapprove asset to swapper: swap asset to USDP
     * @param asset The address of the collateral
     * @param swapper The address of swapper (for swap asset->usdp)
     * @param assetAmountToUser The amount of the collateral to withdraw
     * @param assetAmountToSwap The amount of the collateral to swap to USDP
     * @param minSwappedUsdpAmount min USDP amount which user must get after swap assetAmountToSwap (in case of slippage)
     */
    function exitWithDeleverage(
        address asset,
        ISwapper swapper,
        uint assetAmountToUser,
        uint assetAmountToSwap,
        uint minSwappedUsdpAmount,
        KeydonixOracleAbstract.ProofDataStruct calldata proofData
    ) public nonReentrant checkpoint(asset, msg.sender) returns (uint) {
        return _exitWithDeleverage(
            asset,
            asset,
            false,
            swapper,
            assetAmountToUser,
            assetAmountToSwap,
            minSwappedUsdpAmount,
            proofData
        );
    }

    /**
      * @notice Repayment is the sum of the principal and interest
      * @dev Withdraws collateral and repays specified amount of debt
      * @param asset The address of the collateral
      * @param assetAmount The amount of the collateral to withdraw
      * @param repayment The target repayment amount
      **/
    function exit_targetRepayment(address asset, uint assetAmount, uint repayment, KeydonixOracleAbstract.ProofDataStruct calldata proofData) external returns (uint) {

        uint usdpAmount = _calcPrincipal(asset, msg.sender, repayment);

        return exit(asset, assetAmount, usdpAmount, proofData);
    }

    /**
      * @notice Withdraws wrapped asset and unwrap it, repays specified amount of debt
      * @param wrappedAsset Address of wrapped asset
      * @param assetAmount The amount of the collateral to withdrae
      * @param usdpAmount The amount of USDP token to repay
      **/
    function unwrapAndExit(IWrappedAsset wrappedAsset, uint assetAmount, uint usdpAmount, KeydonixOracleAbstract.ProofDataStruct calldata proofData) public returns (uint) {
        usdpAmount = exit(address(wrappedAsset), assetAmount, usdpAmount, proofData);
        if (assetAmount > 0) {
            wrappedAsset.withdraw(msg.sender, assetAmount);
        }

        return usdpAmount;
    }

    /**
      * @notice Withdraws wrapped asset and unwrap it, repays specified amount of debt
      * @notice Repayment is the sum of the principal and interest
      * @param wrappedAsset Address of wrapped asset
      * @param assetAmount The amount of the collateral to withdrae
      * @param repayment The amount of USDP token to repay
      **/
    function unwrapAndExitTargetRepayment(IWrappedAsset wrappedAsset, uint assetAmount, uint repayment, KeydonixOracleAbstract.ProofDataStruct calldata proofData) public returns (uint) {
        uint usdpAmount = _calcPrincipal(address(wrappedAsset), msg.sender, repayment);
        return unwrapAndExit(wrappedAsset, assetAmount, usdpAmount, proofData);
    }

    /**
     * @notice Withdraws asset and repay debt without USDP needed. assetAmountToSwap would be swaped to USDP internally
     * @notice User must:
     * @notice  - preapprove USDP to vault: pay stability fee
     * @notice  - preapprove asset (underlying token of wrapped asset) to swapper: swap asset to USDP
     * @param wrappedAsset The address of the wrapped asset
     * @param swapper The address of swapper (for swap asset->usdp)
     * @param assetAmountToUser The amount of the collateral to withdraw
     * @param assetAmountToSwap The amount of the collateral to swap to USDP
     * @param minSwappedUsdpAmount min USDP amount which user must get after swap assetAmountToSwap (in case of slippage)
     */
    function unwrapAndExitWithDeleverage(
        IWrappedAsset wrappedAsset,
        ISwapper swapper,
        uint assetAmountToUser,
        uint assetAmountToSwap,
        uint minSwappedUsdpAmount,
        KeydonixOracleAbstract.ProofDataStruct calldata proofData
    ) public nonReentrant checkpoint(address(wrappedAsset), msg.sender) returns (uint) {
        return _exitWithDeleverage(
            address(wrappedAsset),
            address(wrappedAsset.getUnderlyingToken()),
            true,
            swapper,
            assetAmountToUser,
            assetAmountToSwap,
            minSwappedUsdpAmount,
            proofData
        );
    }

    function _joinWithLeverage(
        address asset,
        address tokenToSwap,
        bool isWrappedAsset,
        ISwapper swapper,
        uint assetAmount,
        uint usdpAmount,
        uint minSwappedAssetAmount,
        KeydonixOracleAbstract.ProofDataStruct calldata proofData
    ) internal {
        require(assetAmount != 0 && usdpAmount != 0 && minSwappedAssetAmount != 0, "Unit Protocol: INVALID_AMOUNT");
        require(IToken(asset).decimals() <= 18, "Unit Protocol: NOT_SUPPORTED_DECIMALS");
        require(swappersRegistry.hasSwapper(swapper), "Unit Protocol: UNKNOWN_SWAPPER");

        uint usdpAmountToUser = _mintUsdp(asset, msg.sender, usdpAmount);
        uint swappedAssetAmount = _swapUsdpToAssetAndCheck(swapper, tokenToSwap, usdpAmountToUser, minSwappedAssetAmount);

        uint totalAssetAmount = assetAmount.add(swappedAssetAmount);
        if (isWrappedAsset) {
            IWrappedAsset(asset).deposit(msg.sender, totalAssetAmount);
        }

        vault.depositMain(asset, msg.sender, totalAssetAmount);
        _ensurePositionCollateralization(asset, msg.sender, proofData);

        emit Join(asset, msg.sender, totalAssetAmount, usdpAmount);
        emit JoinWithLeverage(asset, msg.sender, assetAmount, swappedAssetAmount, usdpAmount);
    }

    function _exitWithDeleverage(
        address asset,
        address tokenToSwap,
        bool isWrappedAsset,
        ISwapper swapper,
        uint assetAmountToUser,
        uint assetAmountToSwap,
        uint minSwappedUsdpAmount,
        KeydonixOracleAbstract.ProofDataStruct calldata proofData
    ) internal returns (uint) {
        require(assetAmountToSwap !=0 && minSwappedUsdpAmount != 0, "Unit Protocol: INVALID_AMOUNT");
        require(swappersRegistry.hasSwapper(swapper), "Unit Protocol: UNKNOWN_SWAPPER");

        uint debt = vault.debts(asset, msg.sender);
        require(debt > 0, "Unit Protocol: INVALID_USAGE");

        uint assetAmountToWithdraw = assetAmountToUser.add(assetAmountToSwap);
        vault.withdrawMain(asset, msg.sender, assetAmountToWithdraw);

        if (isWrappedAsset) {
            IWrappedAsset(asset).withdraw(msg.sender, assetAmountToWithdraw);
        }

        uint swappedUsdpAmount = _swapAssetToUsdpAndCheck(swapper, tokenToSwap, assetAmountToSwap, minSwappedUsdpAmount);

        uint usdpAmount = _calcPrincipal(asset, msg.sender, swappedUsdpAmount);
        require(usdpAmount > 0, "Unit Protocol: INVALID_USDP_AMOUNT");

        // catch full repayment
        if (usdpAmount > debt) { usdpAmount = debt; }

        if (debt == usdpAmount) {
            _repay(asset, msg.sender, usdpAmount);
        } else {
            _ensureOracle(asset);

            _repay(asset, msg.sender, usdpAmount);
            vault.update(asset, msg.sender);

            _ensurePositionCollateralization(asset, msg.sender, proofData);
        }

        emit Exit(asset, msg.sender, assetAmountToWithdraw, usdpAmount);
        emit ExitWithDeleverage(asset, msg.sender, assetAmountToUser, assetAmountToSwap, usdpAmount);

        return usdpAmount;
    }

    function _ensurePositionCollateralization(address asset, address owner, KeydonixOracleAbstract.ProofDataStruct calldata proofData) internal view {
        // collateral value of the position in USD
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner, proofData);

        // USD limit of the position
        uint usdLimit = usdValue_q112 * vaultManagerParameters.initialCollateralRatio(asset) / Q112 / 100;

        // revert if collateralization is not enough
        require(vault.getTotalDebt(asset, owner) <= usdLimit, "Unit Protocol: UNDERCOLLATERALIZED");
    }

    // Liquidation Trigger

    /**
     * @dev Triggers liquidation of a position
     * @param asset The address of the collateral token of a position
     * @param owner The owner of the position
     **/
    function triggerLiquidation(address asset, address owner, KeydonixOracleAbstract.ProofDataStruct calldata proofData) external nonReentrant {

        _ensureOracle(asset);

        // USD value of the collateral
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner, proofData);

        // reverts if a position is not liquidatable
        require(_isLiquidatablePosition(asset, owner, usdValue_q112), "Unit Protocol: SAFE_POSITION");

        uint liquidationDiscount_q112 = usdValue_q112.mul(
            vaultManagerParameters.liquidationDiscount(asset)
        ).div(DENOMINATOR_1E5);

        uint initialLiquidationPrice = usdValue_q112.sub(liquidationDiscount_q112).div(Q112);

        // sends liquidation command to the Vault
        vault.triggerLiquidation(asset, owner, initialLiquidationPrice);

        // fire an liquidation event
        emit LiquidationTriggered(asset, owner);
    }

    function getCollateralUsdValue_q112(address asset, address owner, KeydonixOracleAbstract.ProofDataStruct calldata proofData) public view returns (uint) {
        return KeydonixOracleAbstract(oracleRegistry.oracleByAsset(asset)).assetToUsd(asset, vault.collaterals(asset, owner), proofData);
    }

    /**
     * @dev Determines whether a position is liquidatable
     * @param asset The address of the collateral
     * @param owner The owner of the position
     * @return boolean value, whether a position is liquidatable
     **/
    function isLiquidatablePosition(
        address asset,
        address owner,
        KeydonixOracleAbstract.ProofDataStruct calldata proofData
    ) external view returns (bool) {
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner, proofData);

        return _isLiquidatablePosition(asset, owner, usdValue_q112);
    }

    /**
     * @dev Calculates current utilization ratio
     * @param asset The address of the collateral
     * @param owner The owner of the position
     * @return utilization ratio
     **/
    function utilizationRatio(
        address asset,
        address owner,
        KeydonixOracleAbstract.ProofDataStruct calldata proofData
    ) public view returns (uint) {
        uint debt = vault.getTotalDebt(asset, owner);
        if (debt == 0) return 0;

        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner, proofData);

        return debt.mul(100).mul(Q112).div(usdValue_q112);
    }

    function _ensureOracle(address asset) internal view override returns (uint oracleType) {
        oracleType = super._ensureOracle(asset);

        uint[] memory keydonixOracleTypes = oracleRegistry.getKeydonixOracleTypes();
        bool wasKeydonixOracleFound = false;
        for (uint i = 0; i < keydonixOracleTypes.length; i++) {
            if (keydonixOracleTypes[i] == oracleType) {
                wasKeydonixOracleFound = true;
                break;
            }
        }
        require(wasKeydonixOracleFound, "Unit Protocol: NO_KEYDONIX_ORACLE_FOUND");
    }
}