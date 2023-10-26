// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IConvertor {
    function convert(address _for, uint256 _amount, uint256 _mode) external;

    function convertFor(
        uint256 _amountIn,
        uint256 _convertRatio,
        uint256 _minRec,
        address _for,
        uint256 _mode
    ) external;
}