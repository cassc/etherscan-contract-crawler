// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IReinvestment.sol";
import "../../interfaces/IUserData.sol";
import "../../configuration/UserConfiguration.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "./HelpersLogic.sol";
import "./ValidationLogic.sol";
import "./CollateralLogic.sol";
import "./ReserveLogic.sol";
import "../storage/LedgerStorage.sol";

library CollateralPoolLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using CollateralLogic for DataTypes.CollateralData;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 3;

    event DepositedCollateral(address indexed user, address indexed asset, address indexed reinvestment, uint256 amount);
    event WithdrawnCollateral(address indexed user, address indexed asset, address indexed reinvestment, uint256 amount);
    event EmergencyWithdrawnCollateral(address indexed asset, address indexed reinvestment, uint256 supply);
    event ReinvestedCollateralSupply(address indexed asset, address indexed reinvestment, uint256 supply);

    function executeDepositCollateral(
        address user,
        address asset,
        address reinvestment,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];
        DataTypes.CollateralData memory localCollateral = collateral;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        uint256 currCollateralSupply = localCollateral.getCollateralSupply();
        uint256 currUserCollateralBalance = IUserData(protocolConfig.userData).getUserCollateralInternal(
            user, pid, currCollateralSupply, assetConfig.decimals
        );

        ValidationLogic.validateDepositCollateral(localCollateral, userLastTradeBlock, amount, currUserCollateralBalance);

        IUserData(protocolConfig.userData).depositCollateral(user, pid, amount, assetConfig.decimals, currCollateralSupply);

        IERC20Upgradeable(asset).safeTransferFrom(user, address(this), amount);

        if (reinvestment != address(0)) {
            HelpersLogic.approveMax(asset, reinvestment, amount);

            IReinvestment(reinvestment).checkpoint(user, currUserCollateralBalance);
            IReinvestment(reinvestment).invest(amount);
        } else {
            collateral.liquidSupply += amount;
        }

        emit DepositedCollateral(user, asset, reinvestment, amount);
    }

    struct ExecuteWithdrawVars {
        DataTypes.CollateralData collateralCache;
        uint256 currCollateralSupply;
        uint256 currUserCollateralBalance;
        uint256 maxAmountToWithdraw;
        uint256 feeAmount;
    }

    function executeWithdrawCollateral(
        address user,
        address asset,
        address reinvestment,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];
        DataTypes.CollateralData memory localCollateral = collateral;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        ExecuteWithdrawVars memory vars;

        vars.currCollateralSupply = localCollateral.getCollateralSupply();
        vars.currUserCollateralBalance = IUserData(protocolConfig.userData).getUserCollateralInternal(
            user, pid, vars.currCollateralSupply, assetConfig.decimals
        );

        vars.maxAmountToWithdraw = IUserData(protocolConfig.userData).getUserCollateral(user, asset, reinvestment, true);

        // only allow certain amount to withdraw
        if (amount > vars.maxAmountToWithdraw) {
            amount = vars.maxAmountToWithdraw;
        }

        ValidationLogic.validateWithdrawCollateral(
            localCollateral,
            userLastTradeBlock,
            amount,
            vars.maxAmountToWithdraw,
            vars.currCollateralSupply
        );

        IUserData(protocolConfig.userData).withdrawCollateral(
            user,
            pid,
            amount,
            vars.currCollateralSupply,
            assetConfig.decimals
        );

        if (reinvestment != address(0)) {
            IReinvestment(reinvestment).checkpoint(user, vars.currUserCollateralBalance);
            IReinvestment(reinvestment).divest(amount);
        } else {
            collateral.liquidSupply -= amount;
        }

        if (localCollateral.configuration.depositFeeMantissaGwei > 0) {
            vars.feeAmount = amount.wadMul(
                uint256(localCollateral.configuration.depositFeeMantissaGwei).unitToWad(9)
            );

            IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, vars.feeAmount);
        }

        IERC20Upgradeable(asset).safeTransfer(user, amount - vars.feeAmount);

        emit WithdrawnCollateral(user, asset, reinvestment, amount - vars.feeAmount);
    }

    function executeEmergencyWithdrawCollateral(uint256 pid) external {
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];

        uint256 priorBalance = IERC20Upgradeable(collateral.asset).balanceOf(address(this));

        uint256 withdrawn = IReinvestment(collateral.reinvestment).emergencyWithdraw();

        uint256 receivedBalance = IERC20Upgradeable(collateral.asset).balanceOf(address(this)) - priorBalance;
        require(receivedBalance == withdrawn, Errors.ERROR_EMERGENCY_WITHDRAW);

        collateral.liquidSupply += withdrawn;

        emit EmergencyWithdrawnCollateral(collateral.asset, collateral.reinvestment, withdrawn);
    }

    function executeReinvestCollateralSupply(uint256 pid) external {
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];

        IERC20Upgradeable(collateral.asset).safeApprove(collateral.reinvestment, collateral.liquidSupply);
        IReinvestment(collateral.reinvestment).invest(collateral.liquidSupply);

        emit ReinvestedCollateralSupply(collateral.asset, collateral.reinvestment, collateral.liquidSupply);

        collateral.liquidSupply = 0;
    }

    function claimReinvestmentRewards(
        address user,
        address asset,
        address reinvestment
    ) external {
        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];

        ValidationLogic.validateClaimReinvestmentRewards(collateral);

        uint256 currBalance = IUserData(LedgerStorage.getProtocolConfig().userData).getUserCollateral(user, asset, reinvestment, false);

        IReinvestment(reinvestment).claim(user, currBalance);
    }
}