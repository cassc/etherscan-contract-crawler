// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

interface IStargateRouter {
    function addLiquidity(uint256 _poolId, uint256 _amountLD, address to) external payable;
    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLD, address to) external payable;
}