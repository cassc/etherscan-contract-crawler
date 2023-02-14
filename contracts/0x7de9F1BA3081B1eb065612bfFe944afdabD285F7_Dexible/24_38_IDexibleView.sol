//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IDexibleView {
    function revshareSplitRatio() external view returns (uint8);
         
    function stdBpsRate() external view returns (uint16);

    function minBpsRate() external view returns (uint16);

    function minFeeUSD() external view returns (uint112);
        
    function communityVault() external view returns(address);

    function treasury() external view returns (address);

    function dxblToken() external view returns(address);

    function arbitrumGasOracle() external view returns(address);
}