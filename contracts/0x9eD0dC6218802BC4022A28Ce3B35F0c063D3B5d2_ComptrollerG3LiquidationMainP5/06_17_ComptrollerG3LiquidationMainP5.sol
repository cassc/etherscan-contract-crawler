// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ComptrollerG3Liquidation.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract ComptrollerG3LiquidationMainP5 is ComptrollerG3Liquidation {
    function getLiquidationExtraRepayAmount() public view override returns(uint) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0xAa95c2d1B3F78e86C41b22f3d202D15200a23E23;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).extraRepayAmount();
        } else {
            return 0;
        }
    }

    function getLiquidationSeizeIndexes() public view override returns(uint[] memory) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0xAa95c2d1B3F78e86C41b22f3d202D15200a23E23;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).seizeIndexes();
        } else {
            uint[] memory seizeIndexes;
            return seizeIndexes;
        }
    }
}