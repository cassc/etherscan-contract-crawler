// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../types/DataTypes.sol";
import "../../configuration/UserConfiguration.sol";
import "../math/MathUtils.sol";
import "./HelpersLogic.sol";
import "./ReserveLogic.sol";
import "../../interfaces/IUserData.sol";
import "../../interfaces/IBonusPool.sol";
import "../storage/LedgerStorage.sol";

library ReservePoolLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 5;

    event DepositedReserve(address indexed user, address indexed asset, address indexed reinvestment, uint256 amount);
    event WithdrawnReserve(address indexed user, address indexed asset, address indexed reinvestment, uint256 amount);
    event EmergencyWithdrawnReserve(address indexed asset, uint256 supply);
    event ReinvestedReserveSupply(address indexed asset, uint256 supply);
    event EmergencyWithdrawnLong(address indexed asset, uint256 supply, uint256 amountToTreasury);
    event ReinvestedLongSupply(address indexed asset, uint256 supply);
    event SweepLongReinvestment(address indexed asset, uint256 amountToTreasury);

    function setReserveConfiguration(uint256 pid, DataTypes.ReserveConfiguration memory configuration) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        require(reserve.asset != address(0), Errors.POOL_NOT_INITIALIZED);
        reserve.updateIndex();
        reserve.postUpdateReserveData();
        reserve.configuration = configuration;
    }

    function getReserveIndexes(address asset) external view returns (uint256, uint256, uint256) {
        return LedgerStorage.getReserveStorage().reserves[
            LedgerStorage.getReserveStorage().reservesList[asset]
        ].getReserveIndexes();
    }

    function getReserveSupplies(address asset) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return LedgerStorage.getReserveStorage().reserves[
            LedgerStorage.getReserveStorage().reservesList[asset]
        ].getReserveSupplies();
    }

    function checkpointReserve(address asset) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[
            LedgerStorage.getReserveStorage().reservesList[asset]
        ];

        reserve.updateIndex();
        reserve.postUpdateReserveData();
    }

    function executeDepositReserve(
        address user, address asset, uint256 amount
    ) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.ReserveData memory localReserve = reserve;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        ValidationLogic.validateDepositReserve(localReserve, amount);

        reserve.updateIndex();

        (,uint256 currReserveSupply,,,) = reserve.getReserveSupplies();
        uint256 currUserReserveBalance = IUserData(protocolConfig.userData).getUserReserve(user, asset, false);

        IUserData(protocolConfig.userData).depositReserve(user, pid, amount, assetConfig.decimals, currReserveSupply);

        IERC20Upgradeable(asset).safeTransferFrom(user, address(this), amount);

        if (localReserve.ext.reinvestment != address(0)) {
            HelpersLogic.approveMax(asset, localReserve.ext.reinvestment, amount);

            IReinvestment(localReserve.ext.reinvestment).checkpoint(user, currUserReserveBalance);
            IReinvestment(localReserve.ext.reinvestment).invest(amount);
        } else {
            reserve.liquidSupply += amount;
        }

        if (localReserve.ext.bonusPool != address(0)) {
            uint256 nextUserReserveBalance = IUserData(protocolConfig.userData).getUserReserve(user, asset, false);
            IBonusPool(localReserve.ext.bonusPool).updatePoolUser(asset, user, nextUserReserveBalance);
        }

        reserve.postUpdateReserveData();

        emit DepositedReserve(user, asset, localReserve.ext.reinvestment, amount);
    }

    function executeWithdrawReserve(
        address user, address asset, uint256 amount
    ) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.ReserveData memory localReserve = reserve;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        reserve.updateIndex();

        (,uint256 currReserveSupply,,,) = reserve.getReserveSupplies();

        uint256 currUserReserveBalance = IUserData(protocolConfig.userData).getUserReserve(user, asset, false);
        uint256 currUserMaxClaimReserve = IUserData(protocolConfig.userData).getUserReserve(user, asset, true);

        if (amount > currUserMaxClaimReserve) {
            amount = currUserMaxClaimReserve;
        }

        ValidationLogic.validateWithdrawReserve(localReserve, currReserveSupply, amount);

        IUserData(protocolConfig.userData).withdrawReserve(user, pid, amount, assetConfig.decimals, currReserveSupply);

        if (localReserve.ext.reinvestment != address(0)) {
            IReinvestment(localReserve.ext.reinvestment).checkpoint(user, currUserReserveBalance);
            IReinvestment(localReserve.ext.reinvestment).divest(amount);
        } else {
            reserve.liquidSupply -= amount;
        }

        uint256 withdrawalFee;
        if (localReserve.configuration.depositFeeMantissaGwei > 0) {
            withdrawalFee = amount.wadMul(
                uint256(localReserve.configuration.depositFeeMantissaGwei).unitToWad(9)
            );

            IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, withdrawalFee);
        }

        if (localReserve.ext.bonusPool != address(0)) {
            uint256 nextUserReserveBalance = IUserData(protocolConfig.userData).getUserReserve(user, asset, false);
            IBonusPool(localReserve.ext.bonusPool).updatePoolUser(asset, user, nextUserReserveBalance);
        }

        reserve.postUpdateReserveData();

        IERC20Upgradeable(asset).safeTransfer(user, amount - withdrawalFee);

        emit WithdrawnReserve(user, asset, localReserve.ext.reinvestment, amount - withdrawalFee);
    }

    function executeEmergencyWithdrawReserve(uint256 pid) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];

        uint256 priorBalance = IERC20Upgradeable(reserve.asset).balanceOf(address(this));

        uint256 withdrawn = IReinvestment(reserve.ext.reinvestment).emergencyWithdraw();

        uint256 receivedBalance = IERC20Upgradeable(reserve.asset).balanceOf(address(this)) - priorBalance;
        require(receivedBalance == withdrawn, Errors.ERROR_EMERGENCY_WITHDRAW);

        reserve.liquidSupply += withdrawn;

        emit EmergencyWithdrawnReserve(reserve.asset, withdrawn);
    }

    function executeReinvestReserveSupply(uint256 pid) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];

        IERC20Upgradeable(reserve.asset).safeApprove(reserve.ext.reinvestment, reserve.liquidSupply);
        IReinvestment(reserve.ext.reinvestment).invest(reserve.liquidSupply);

        emit ReinvestedReserveSupply(reserve.asset, reserve.liquidSupply);

        reserve.liquidSupply = 0;
    }

    function executeEmergencyWithdrawLong(uint256 pid) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];

        uint256 priorBalance = IERC20Upgradeable(reserve.asset).balanceOf(address(this));

        uint256 withdrawn = IReinvestment(reserve.ext.longReinvestment).emergencyWithdraw();

        uint256 receivedBalance = IERC20Upgradeable(reserve.asset).balanceOf(address(this)) - priorBalance;
        require(receivedBalance == withdrawn, Errors.ERROR_EMERGENCY_WITHDRAW);

        uint256 amountToTreasury = withdrawn - reserve.longSupply;

        if (amountToTreasury > 0) {
            IERC20Upgradeable(reserve.asset).safeTransfer(protocolConfig.treasury, amountToTreasury);
        }

        emit EmergencyWithdrawnLong(reserve.asset, reserve.longSupply, amountToTreasury);
    }

    // @dev long supply is static and always has value, accrued amount from reinvestment will be transferred to treasury
    // @param reserve Reserve data
    function executeReinvestLongSupply(uint256 pid) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];

        IERC20Upgradeable(reserve.asset).safeApprove(reserve.ext.longReinvestment, reserve.longSupply);
        IReinvestment(reserve.ext.longReinvestment).invest(reserve.longSupply);

        emit ReinvestedLongSupply(reserve.asset, reserve.longSupply);
    }

    function executeSweepLongReinvestment(address asset) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        require(pid != 0, Errors.POOL_NOT_INITIALIZED);

        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.ReserveData memory localReserve = reserve;

        reserve.updateIndex();

        require(localReserve.ext.longReinvestment != address(0), Errors.INVALID_ZERO_ADDRESS);

        uint256 reinvestmentBalance = IReinvestment(localReserve.ext.longReinvestment).totalSupply();
        uint256 amountToTreasury = reinvestmentBalance - reserve.longSupply;

        require(amountToTreasury > 0, Errors.INVALID_ZERO_AMOUNT);

        IReinvestment(localReserve.ext.longReinvestment).divest(amountToTreasury);
        IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, amountToTreasury);

        reserve.postUpdateReserveData();

        emit SweepLongReinvestment(asset, amountToTreasury);
    }
}