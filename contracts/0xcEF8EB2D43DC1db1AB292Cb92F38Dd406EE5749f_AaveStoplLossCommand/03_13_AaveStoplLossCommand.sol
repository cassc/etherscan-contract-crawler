// SPDX-License-Identifier: AGPL-3.0-or-later

/// AaveStoplLossCommand.sol

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

pragma solidity 0.8.13;
import { IServiceRegistry } from "../interfaces/IServiceRegistry.sol";
import { ILendingPool } from "../interfaces/AAVE/ILendingPool.sol";
import { IAccountImplementation } from "../interfaces/IAccountImplementation.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SwapData } from "./../libs/EarnSwapData.sol";
import { ISwap } from "./../interfaces/ISwap.sol";
import { DataTypes } from "../libs/AAVEDataTypes.sol";
import { BaseAAveFlashLoanCommand } from "./BaseAAveFlashLoanCommand.sol";
import { IWETH } from "../interfaces/IWETH.sol";

struct AaveData {
    address collateralTokenAddress;
    address debtTokenAddress;
    address borrower;
    address payable fundsReceiver;
}

struct AddressRegistry {
    address aaveStopLoss;
    address exchange;
}

struct StopLossTriggerData {
    address positionAddress;
    uint16 triggerType;
    address collateralToken;
    address debtToken;
    uint256 slLevel;
}

struct CloseData {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] modes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
}

interface AaveStopLoss {
    function closePosition(
        SwapData calldata exchangeData,
        AaveData memory aaveData,
        AddressRegistry calldata addressRegistry
    ) external;

    function trustedCaller() external returns (address);

    function self() external returns (address);
}

contract AaveStoplLossCommand is BaseAAveFlashLoanCommand {
    string private constant OPERATION_EXECUTOR = "OPERATION_EXECUTOR";
    string private constant AAVE_POOL = "AAVE_POOL";
    string private constant AUTOMATION_BOT = "AUTOMATION_BOT_V2";
    string private constant WETH = "WETH";

    constructor(
        IServiceRegistry _serviceRegistry,
        ILendingPool _lendingPool
    ) BaseAAveFlashLoanCommand(_serviceRegistry, _lendingPool) {}

    function validateTriggerType(uint16 triggerType, uint16 expectedTriggerType) public pure {
        require(triggerType == expectedTriggerType, "base-aave-fl-command/type-not-supported");
    }

    function validateSelector(bytes4 expectedSelector, bytes memory executionData) public pure {
        bytes4 selector = abi.decode(executionData, (bytes4));
        require(selector == expectedSelector, "base-aave-fl-command/invalid-selector");
    }

    function isExecutionCorrect(bytes memory triggerData) external view override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );
        address weth = address(serviceRegistry.getRegisteredService(WETH));
        require(reciveExpected == false, "base-aave-fl-command/contract-not-empty");
        require(
            IERC20(stopLossTriggerData.collateralToken).balanceOf(self) == 0 &&
                IERC20(stopLossTriggerData.debtToken).balanceOf(self) == 0 &&
                (stopLossTriggerData.collateralToken != weth ||
                    (IERC20(weth).balanceOf(self) == 0 && self.balance == 0)),
            "base-aave-fl-command/contract-not-empty"
        );
        (uint256 totalCollateralETH, uint256 totalDebtETH, , , , ) = lendingPool.getUserAccountData(
            stopLossTriggerData.positionAddress
        );

        return !(totalCollateralETH > 0 && totalDebtETH > 0);
    }

    function isExecutionLegal(bytes memory triggerData) external view override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );

        (uint256 totalCollateralETH, uint256 totalDebtETH, , , , ) = lendingPool.getUserAccountData(
            stopLossTriggerData.positionAddress
        );

        if (totalDebtETH == 0) return false;

        uint256 ltv = (10 ** 8 * totalDebtETH) / totalCollateralETH;
        bool vaultHasDebt = totalDebtETH != 0;
        return vaultHasDebt && ltv >= stopLossTriggerData.slLevel;
    }

    function execute(
        bytes calldata executionData,
        bytes memory triggerData
    ) external override nonReentrant {
        require(
            serviceRegistry.getRegisteredService(AUTOMATION_BOT) == msg.sender,
            "aaveSl/caller-not-bot"
        );

        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );
        trustedCaller = stopLossTriggerData.positionAddress;
        validateSelector(AaveStopLoss.closePosition.selector, executionData);
        IAccountImplementation(stopLossTriggerData.positionAddress).execute(self, executionData);

        trustedCaller = address(0);
    }

    function isTriggerDataValid(
        bool continuous,
        bytes memory triggerData
    ) external pure override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );

        return
            !continuous &&
            stopLossTriggerData.slLevel < 10 ** 8 &&
            (stopLossTriggerData.triggerType == 10 || stopLossTriggerData.triggerType == 11);
    }

    function closePosition(
        SwapData calldata exchangeData,
        AaveData memory aaveData,
        AddressRegistry calldata addressRegistry
    ) external {
        require(
            AaveStopLoss(addressRegistry.aaveStopLoss).trustedCaller() == address(this),
            "aaveSl/caller-not-allowed"
        );
        require(self == msg.sender, "aaveSl/msg-sender-is-not-sl");

        DataTypes.ReserveData memory collReserveData = lendingPool.getReserveData(
            aaveData.collateralTokenAddress
        );
        DataTypes.ReserveData memory debtReserveData = lendingPool.getReserveData(
            aaveData.debtTokenAddress
        );
        uint256 totalToRepay = IERC20(debtReserveData.variableDebtTokenAddress).balanceOf(
            aaveData.borrower
        );
        uint256 totalCollateral = IERC20(collReserveData.aTokenAddress).balanceOf(
            aaveData.borrower
        );
        IERC20(collReserveData.aTokenAddress).approve(
            addressRegistry.aaveStopLoss,
            totalCollateral
        );

        {
            CloseData memory closeData;

            address[] memory debtTokens = new address[](1);
            debtTokens[0] = address(aaveData.debtTokenAddress);
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = totalToRepay;
            uint256[] memory modes = new uint256[](1);
            modes[0] = uint256(0);

            closeData.receiverAddress = addressRegistry.aaveStopLoss;
            closeData.assets = debtTokens;
            closeData.amounts = amounts;
            closeData.modes = modes;
            closeData.onBehalfOf = address(this);
            closeData.params = abi.encode(
                collReserveData.aTokenAddress,
                aaveData.collateralTokenAddress,
                addressRegistry.exchange,
                aaveData.borrower,
                aaveData.fundsReceiver,
                exchangeData
            );
            closeData.referralCode = 0;
            lendingPool.flashLoan(
                closeData.receiverAddress,
                closeData.assets,
                closeData.amounts,
                closeData.modes,
                closeData.onBehalfOf,
                closeData.params,
                closeData.referralCode
            );
        }
        IERC20(aaveData.debtTokenAddress).transfer(
            aaveData.fundsReceiver,
            IERC20(aaveData.debtTokenAddress).balanceOf(aaveData.borrower)
        );
    }

    function flashloanAction(bytes memory data) internal override {
        FlData memory flData;
        (flData.assets, flData.amounts, flData.premiums, flData.initiator, flData.params) = abi
            .decode(data, (address[], uint256[], uint256[], address, bytes));
        (
            address aTokenAddress,
            address collateralTokenAddress,
            address exchangeAddress,
            address borrower,
            address fundsReceiver,
            SwapData memory exchangeData
        ) = abi.decode(flData.params, (address, address, address, address, address, SwapData));

        require(flData.initiator == borrower, "aaveSl/initiator-not-borrower");

        IERC20 collateralToken = IERC20(collateralTokenAddress);
        IERC20 debtToken = IERC20(flData.assets[0]);
        IERC20 aToken = IERC20(aTokenAddress);
        uint256 flTotal = (flData.amounts[0] + flData.premiums[0]);
        uint256 aTokenBalance = aToken.balanceOf(borrower);

        _repay(address(debtToken), borrower, flData.amounts[0]);
        _pullTokenAndWithdraw(aToken, collateralTokenAddress, borrower, aTokenBalance);
        _exchange(
            collateralToken,
            debtToken,
            exchangeAddress,
            aTokenBalance,
            flTotal,
            exchangeData
        );
        address weth = address(serviceRegistry.getRegisteredService(WETH));
        if (address(collateralToken) == weth) {
            expectRecive();
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
        SwapData memory exchangeData
    ) internal {
        collateralToken.approve(exchangeAddress, balance);

        uint256 debtTokenBalanceBefore = debtToken.balanceOf(self);
        ISwap(exchangeAddress).swapTokens(exchangeData);
        require(
            (debtToken.balanceOf(self) - debtTokenBalanceBefore) > (flTotal),
            "aaveSl/recieved-too-little-from-swap"
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
        require(reciveExpected == true, "aaveSl/unexpected-eth-receive");
    }
}