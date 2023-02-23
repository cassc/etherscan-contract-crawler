// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IExpectedOutCalculator {
    function getExpectedOut(uint256 _amountIn, address _fromToken, address _toToken, bytes calldata _data)
        external
        view
        returns (uint256);
}