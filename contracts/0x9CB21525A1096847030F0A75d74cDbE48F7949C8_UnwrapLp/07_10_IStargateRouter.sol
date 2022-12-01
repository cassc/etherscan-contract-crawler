// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IStargateRouter {
    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;
    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external;
}