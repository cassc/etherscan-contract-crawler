//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IOptimismGasOracle {
    
    function getL1Fee(bytes calldata data) external view returns(uint);
}