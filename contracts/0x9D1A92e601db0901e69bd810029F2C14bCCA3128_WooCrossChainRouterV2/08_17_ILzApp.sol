// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the LzApp that functions not exist in the @layerzerolabs package
 */
interface ILzApp {
    function minDstGasLookup(uint16 _dstChainId, uint16 _type) external view returns (uint256 _minGasLimit);
}