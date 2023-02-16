//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./oracles/IOptimismGasOracle.sol";
import "./DexibleStorage.sol";
import "../common/LibConstants.sol";
import "./oracles/IStandardGasAdjustments.sol";
import "hardhat/console.sol";

library LibFees {

    //special handling for L2s that impose an L1 rollup fee
    uint constant ARB = 42161;
    uint constant OPT = 10;
    IOptimismGasOracle constant optGasOracle = IOptimismGasOracle(0x420000000000000000000000000000000000000F);

    function computeGasCost(uint gasUsed, bool success) internal view returns(uint) {
        DexibleStorage.DexibleData storage ds = DexibleStorage.load();
        uint add = ds.stdGasAdjustment.adjustment(success ? LibConstants.SWAP_SUCCESS : LibConstants.SWAP_FAILURE);
        gasUsed += add;
        //console.log("Gas used to compute cost in fee token", gasUsed, "after adding", add);
        uint cid;
        assembly {
            cid := chainid()
        }
        if(cid == ARB) {
            return ds.arbitrumGasOracle.calculateGasCost(msg.data.length, gasUsed);
        }
        if(cid == OPT) {
            return (tx.gasprice * gasUsed) + optGasOracle.getL1Fee(msg.data);
        }
       // console.log("Gas fee", tx.gasprice * gasUsed);
        return tx.gasprice * gasUsed;
    }

    function computeMinFeeUnits(address feeToken) internal view returns (uint) {
        DexibleStorage.DexibleData storage rs = DexibleStorage.load();
        if(rs.minFeeUSD == 0) {
            return 0;
        }

        //fee token price is in 30-dec units.
        uint usdPrice = rs.communityVault.feeTokenPriceUSD(feeToken);

        uint8 ftDecs = IERC20Metadata(feeToken).decimals();

        //fee USD configuration is expressed in 18-decimals. Have to convert to fee-token units and 
        //account for price units
        uint minFeeUSD = (rs.minFeeUSD * (ftDecs != 18 ? ((10**ftDecs) / 1e18) : 1)) * LibConstants.PRICE_PRECISION;

        //then simply divide to get fee token units that equate to min fee USD
        return  minFeeUSD / usdPrice;
    }
}