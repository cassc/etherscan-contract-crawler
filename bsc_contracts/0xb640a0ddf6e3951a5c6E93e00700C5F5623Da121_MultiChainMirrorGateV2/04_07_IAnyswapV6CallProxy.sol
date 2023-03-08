// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./AnyCallExecutor.sol";

interface IAnyswapV6CallProxy {

    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);

    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executionBudget(address _account) external returns(uint256);

    function executor() external returns(AnyCallExecutor);
}