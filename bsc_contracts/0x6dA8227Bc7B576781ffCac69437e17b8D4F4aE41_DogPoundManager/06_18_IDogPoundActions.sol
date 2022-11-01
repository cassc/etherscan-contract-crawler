// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDogPoundActions{
    function doSwap(address _from, uint256 _amount, uint256 _taxReduction, address[] memory path) external;
    function doTransfer(address _from, address _to, uint256 _amount, uint256 _taxReduction) external;
}