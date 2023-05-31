// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0;

interface IBestDexV2Callee {
    function BestDexV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}