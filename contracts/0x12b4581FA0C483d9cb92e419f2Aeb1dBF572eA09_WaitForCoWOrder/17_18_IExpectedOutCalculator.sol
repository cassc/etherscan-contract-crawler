// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IExpectedOutCalculator {
    function getExpectedOut(
        uint256 _amountIn,
        address _fromToken,
        address _toToken,
        bytes calldata _data
    ) external view returns (uint256);
}