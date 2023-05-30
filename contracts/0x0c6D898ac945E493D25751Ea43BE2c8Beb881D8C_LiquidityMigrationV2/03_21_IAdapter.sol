//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IAdapter {
    struct Call {
        address target;
        bytes callData;
    }

    function outputTokens(address inputToken) external view returns (address[] memory outputs);

    function encodeMigration(address _genericRouter, address _strategy, address _lp, uint256 _amount)
        external view returns (Call[] memory calls);

    function encodeWithdraw(address _lp, uint256 _amount) external view returns (Call[] memory calls);

    function buy(address _lp, address _exchange, uint256 _minAmountOut, uint256 _deadline) external payable;

    function getAmountOut(address _lp, address _exchange, uint256 _amountIn) external returns (uint256);

    function isWhitelisted(address _token) external view returns (bool);
}