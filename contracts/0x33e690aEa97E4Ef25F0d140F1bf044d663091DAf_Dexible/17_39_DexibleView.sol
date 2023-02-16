//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../interfaces/IDexibleView.sol";
import "../DexibleStorage.sol";

abstract contract DexibleView is IDexibleView {

    function revshareSplitRatio() external view returns (uint8){
        return DexibleStorage.load().revshareSplitRatio;
    }
         
    function stdBpsRate() external view returns (uint16){
        return DexibleStorage.load().stdBpsRate;
    }

    function minBpsRate() external view returns (uint16){
        return DexibleStorage.load().minBpsRate;
    }

    function minFeeUSD() external view returns (uint112){
        return DexibleStorage.load().minFeeUSD;
    }
        
    function communityVault() external view returns(address){
        return address(DexibleStorage.load().communityVault);
    }

    function adminMultiSig() external view returns(address) {
        return DexibleStorage.load().adminMultiSig;
    }

    function treasury() external view returns (address){
        return DexibleStorage.load().treasury;
    }

    function dxblToken() external view returns(address){
        return address(DexibleStorage.load().dxblToken);
    }
    
    function arbitrumGasOracle() external view returns(address){
        return address(DexibleStorage.load().arbitrumGasOracle);
    }

    function stdGasAdjustmentContract() external view returns (address) {
        return address(DexibleStorage.load().stdGasAdjustment);
    }
}