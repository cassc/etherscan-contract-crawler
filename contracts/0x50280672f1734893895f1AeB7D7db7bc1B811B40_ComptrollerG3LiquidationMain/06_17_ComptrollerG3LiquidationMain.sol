// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ComptrollerG3Liquidation.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract ComptrollerG3LiquidationMain is ComptrollerG3Liquidation {
    function getLiquidationExtraRepayAmount() public virtual override view returns(uint) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0xdcBF673B01D80cACE11699BB1511ee285ed62041;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).extraRepayAmount();
        } else {
            return 0;
        }
    }
}