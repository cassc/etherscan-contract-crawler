// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {IFlashLoanReceiver} from "../../interfaces/aave/IFlashLoanReceiver.sol";
import {IFlashLender} from "../../interfaces/aave/IFlashLender.sol";
import {NotionalProxy} from "../../interfaces/notional/NotionalProxy.sol";
import {FlashLiquidatorBase} from "./FlashLiquidatorBase.sol";

contract AaveFlashLiquidator is IFlashLoanReceiver, FlashLiquidatorBase {

    constructor(NotionalProxy notional_, address aave_) 
        FlashLiquidatorBase(notional_, aave_) {
    }

    function _flashLiquidate(
        address asset,
        uint256 amount,
        bool withdraw,
        LiquidationParams calldata params
    ) internal override {
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        assets[0] = asset;
        amounts[0] = amount;

        IFlashLender(FLASH_LENDER).flashLoan(
            address(this),
            assets,
            amounts,
            new uint256[](1), // modes
            address(this),
            abi.encode(asset, amount, withdraw, params),
            0
        );        
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        super.handleLiquidation(premiums[0], false, params); // repay = false for Aave
        return true;
    }
}