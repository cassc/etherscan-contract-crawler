// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ComptrollerG3Liquidation.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract ComptrollerG3LiquidationMain is ComptrollerG3Liquidation {
    function getLiquidationExtraRepayAmount() public view override returns(uint) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0x11FF91f17E43C2C5C241850d261CaE5Febb9B439;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).extraRepayAmount();
        } else {
            return 0;
        }
    }

    function getLiquidationSeizeIndexes() public view override returns(uint[] memory) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0x11FF91f17E43C2C5C241850d261CaE5Febb9B439;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).seizeIndexes();
        } else {
            uint[] memory seizeIndexes;
            return seizeIndexes;
        }
    }
}