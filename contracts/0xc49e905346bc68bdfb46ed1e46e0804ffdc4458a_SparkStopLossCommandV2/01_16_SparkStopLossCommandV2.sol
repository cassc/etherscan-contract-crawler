// SPDX-License-Identifier: AGPL-3.0-or-later

/// SparkStopLossCommandV2.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;
import { IServiceRegistry } from "../interfaces/IServiceRegistry.sol";
import { IFlashLoanRecipient } from "../interfaces/Balancer/IFlashLoanRecipient.sol";
import { IPool } from "../interfaces/Spark/IPool.sol";
import { IAccountImplementation } from "../interfaces/IAccountImplementation.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SwapData } from "./../libs/EarnSwapData.sol";
import { ISwap } from "./../interfaces/ISwap.sol";
// Spark and Aave DataTypes are the same
import { DataTypes } from "../libs/AAVEDataTypes.sol";
import { BaseBalancerFlashLoanCommand } from "./BaseBalancerFlashLoanCommand.sol";
import { IWETH } from "../interfaces/IWETH.sol";

struct SparkData {
    address collateralTokenAddress;
    address debtTokenAddress;
    address borrower;
    address payable fundsReceiver;
}

struct StopLossTriggerData {
    address positionAddress;
    uint16 triggerType;
    uint256 maxCoverage;
    address debtToken;
    address collateralToken;
    uint256 slLevel;
}

struct FlCalldata {
    IFlashLoanRecipient receiverAddress;
    IERC20[] assets;
    uint256[] amounts;
    bytes userData;
}

interface SparkStopLoss {
    function closePosition(SwapData calldata swapData, SparkData memory sparkData) external;

    function trustedCaller() external returns (address);

    function self() external returns (address);
}

contract SparkStopLossCommandV2 is BaseBalancerFlashLoanCommand {
    address public immutable weth;
    address public immutable bot;
    IPool public immutable lendingPool;

    string private constant AUTOMATION_BOT = "AUTOMATION_BOT_V2";
    string private constant SPARK_LENDING_POOL = "SPARK_LENDING_POOL";
    string private constant WETH = "WETH";

    constructor(
        IServiceRegistry _serviceRegistry,
        address exchange_
    ) BaseBalancerFlashLoanCommand(_serviceRegistry, exchange_) {
        lendingPool = IPool(serviceRegistry.getRegisteredService(SPARK_LENDING_POOL));
        weth = serviceRegistry.getRegisteredService(WETH);
        bot = serviceRegistry.getRegisteredService(AUTOMATION_BOT);
    }

    function getTriggerType(bytes calldata triggerData) external view override returns (uint16) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );
        if (!this.isTriggerDataValid(false, triggerData)) {
            return 0;
        }
        return stopLossTriggerData.triggerType;
    }

    function validateTriggerType(uint16 triggerType, uint16 expectedTriggerType) public pure {
        require(triggerType == expectedTriggerType, "base-spark-fl-command/type-not-supported");
    }

    function validateSelector(bytes4 expectedSelector, bytes memory executionData) public pure {
        bytes4 selector = abi.decode(executionData, (bytes4));
        require(selector == expectedSelector, "base-spark-fl-command/invalid-selector");
    }

    function isExecutionCorrect(bytes memory triggerData) external view override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );
        require(receiveExpected == false, "base-spark-fl-command/contract-not-empty");
        require(
            IERC20(stopLossTriggerData.collateralToken).balanceOf(self) == 0 &&
                IERC20(stopLossTriggerData.debtToken).balanceOf(self) == 0 &&
                (stopLossTriggerData.collateralToken != weth ||
                    (IERC20(weth).balanceOf(self) == 0 && self.balance == 0)),
            "base-spark-fl-command/contract-not-empty"
        );
        (uint256 totalCollateralBase, uint256 totalDebtBase, , , , ) = lendingPool
            .getUserAccountData(stopLossTriggerData.positionAddress);

        return !(totalCollateralBase > 0 && totalDebtBase > 0);
    }

    function isExecutionLegal(bytes memory triggerData) external view override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );

        (uint256 totalCollateralBase, uint256 totalDebtBase, , , , ) = lendingPool
            .getUserAccountData(stopLossTriggerData.positionAddress);

        // Calculate the loan-to-value (LTV) ratio for Aave V3
        // LTV is the ratio of the total debt to the total collateral, expressed as a percentage
        // The result is multiplied by 10000 to preserve precision
        // eg 0.67 (67%) LTV is stored as 6700
        uint256 ltv = (totalDebtBase * 10000) / totalCollateralBase;
        if (totalDebtBase == 0) return false;

        bool vaultHasDebt = totalDebtBase != 0;
        return vaultHasDebt && ltv >= stopLossTriggerData.slLevel;
    }

    function execute(
        bytes calldata executionData,
        bytes memory triggerData
    ) external override nonReentrant {
        require(bot == msg.sender, "spark-sl/caller-not-bot");

        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );
        require(
            stopLossTriggerData.triggerType == 113 || stopLossTriggerData.triggerType == 114,
            "spark-sl/invalid-trigger-type"
        );
        trustedCaller = stopLossTriggerData.positionAddress;
        validateSelector(SparkStopLoss.closePosition.selector, executionData);
        IAccountImplementation(stopLossTriggerData.positionAddress).execute(self, executionData);

        trustedCaller = address(0);
    }

    function isTriggerDataValid(
        bool continuous,
        bytes memory triggerData
    ) external view override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );

        return
            !continuous &&
            stopLossTriggerData.slLevel < 10 ** 4 &&
            (stopLossTriggerData.triggerType == 113 || stopLossTriggerData.triggerType == 114);
    }

    function closePosition(SwapData calldata swapData, SparkData memory sparkData) external {
        require(
            SparkStopLoss(self).trustedCaller() == address(this),
            "spark-sl/caller-not-allowed"
        );
        require(
            IAccountImplementation(address(this)).owner() == sparkData.fundsReceiver,
            "spark-sl/funds-receiver-not-owner"
        );
        require(self == msg.sender, "spark-sl/msg-sender-is-not-sl");

        DataTypes.ReserveData memory collReserveData = lendingPool.getReserveData(
            sparkData.collateralTokenAddress
        );
        DataTypes.ReserveData memory debtReserveData = lendingPool.getReserveData(
            sparkData.debtTokenAddress
        );
        uint256 totalToRepay = IERC20(debtReserveData.variableDebtTokenAddress).balanceOf(
            sparkData.borrower
        );
        uint256 totalCollateral = IERC20(collReserveData.aTokenAddress).balanceOf(
            sparkData.borrower
        );
        IERC20(collReserveData.aTokenAddress).approve(self, totalCollateral);

        {
            FlCalldata memory flCalldata;

            IERC20[] memory debtTokens = new IERC20[](1);
            debtTokens[0] = IERC20(sparkData.debtTokenAddress);
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = totalToRepay;

            flCalldata.receiverAddress = IFlashLoanRecipient(self);
            flCalldata.assets = debtTokens;
            flCalldata.amounts = amounts;
            flCalldata.userData = abi.encode(
                collReserveData.aTokenAddress,
                sparkData.collateralTokenAddress,
                swap,
                sparkData.borrower,
                sparkData.fundsReceiver,
                swapData
            );
            balancerVault.flashLoan(
                flCalldata.receiverAddress,
                flCalldata.assets,
                flCalldata.amounts,
                flCalldata.userData
            );
        }
        IERC20(sparkData.debtTokenAddress).transfer(
            sparkData.fundsReceiver,
            IERC20(sparkData.debtTokenAddress).balanceOf(sparkData.borrower)
        );
    }

    function flashloanAction(bytes memory data) internal override {
        FlActionData memory flActionData = abi.decode(data, (FlActionData));
        (
            address aTokenAddress,
            address collateralTokenAddress,
            address exchangeAddress,
            address borrower,
            address fundsReceiver,
            SwapData memory swapData
        ) = abi.decode(
                flActionData.userData,
                (address, address, address, address, address, SwapData)
            );

        IERC20 collateralToken = IERC20(collateralTokenAddress);
        IERC20 debtToken = IERC20(flActionData.assets[0]);
        IERC20 aToken = IERC20(aTokenAddress);
        uint256 flTotal = (flActionData.amounts[0] + flActionData.premiums[0]);
        uint256 aTokenBalance = aToken.balanceOf(borrower);

        _repay(address(debtToken), borrower, flActionData.amounts[0]);
        _pullTokenAndWithdraw(aToken, collateralTokenAddress, borrower, aTokenBalance);
        _exchange(collateralToken, debtToken, exchangeAddress, aTokenBalance, flTotal, swapData);
        if (address(collateralToken) == weth) {
            expectReceive();
            uint256 balance = IERC20(weth).balanceOf(self);
            IWETH(weth).withdraw(balance);
            ethReceived();
            payable(fundsReceiver).transfer(self.balance);
        } else {
            _transfer(address(collateralToken), fundsReceiver, 0);
        }
        _transfer(address(debtToken), fundsReceiver, debtToken.balanceOf(self) - flTotal);
    }

    function _transfer(address token, address to, uint256 amount) internal {
        if (amount == 0) {
            IERC20(token).transfer(to, IERC20(token).balanceOf(self));
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    function _repay(address token, address onBehalf, uint256 amount) internal {
        IERC20(token).approve(address(lendingPool), amount);
        lendingPool.repay(token, amount, 2, onBehalf);
    }

    function _exchange(
        IERC20 collateralToken,
        IERC20 debtToken,
        address exchangeAddress,
        uint256 balance,
        uint256 flTotal,
        SwapData memory swapData
    ) internal {
        collateralToken.approve(exchangeAddress, balance);

        uint256 debtTokenBalanceBefore = debtToken.balanceOf(self);
        ISwap(exchangeAddress).swapTokens(swapData);
        require(
            (debtToken.balanceOf(self) - debtTokenBalanceBefore) > (flTotal),
            "aave-v3-sl/recieved-too-little-from-swap"
        );
    }

    function _pullTokenAndWithdraw(
        IERC20 aToken,
        address collateralTokenAddress,
        address borrower,
        uint256 balance
    ) internal {
        aToken.transferFrom(borrower, self, balance);
        lendingPool.withdraw(collateralTokenAddress, (type(uint256).max), self);
    }

    receive() external payable {
        require(receiveExpected == true, "aave-v3-sl/unexpected-eth-receive");
    }
}