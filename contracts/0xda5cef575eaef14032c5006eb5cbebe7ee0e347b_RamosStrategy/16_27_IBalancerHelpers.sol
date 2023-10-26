pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/external/balancer/IBalancerHelpers.sol)

import { IBalancerVault } from "contracts/interfaces/external/balancer/IBalancerVault.sol";

interface IBalancerHelpers {
    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        IBalancerVault.JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        IBalancerVault.ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}