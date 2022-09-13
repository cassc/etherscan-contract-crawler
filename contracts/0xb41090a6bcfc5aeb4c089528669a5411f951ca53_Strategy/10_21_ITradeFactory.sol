// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.12;

struct AsyncTradeExecutionDetails {
    address _strategy;
    address _tokenIn;
    address _tokenOut;
    uint256 _amount;
    uint256 _minAmountOut;
}

interface ITradeFactory {
    function enable(address rewards, address want) external;

    function grantRole(bytes32 role, address account) external;

    function STRATEGY() external view returns (bytes32);

    function execute(
        AsyncTradeExecutionDetails calldata _tradeExecutionDetails,
        address _swapper,
        bytes calldata _data
  ) external returns (uint256 _receivedAmount);
}