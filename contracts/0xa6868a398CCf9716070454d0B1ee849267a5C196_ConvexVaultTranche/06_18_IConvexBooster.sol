pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexBooster.sol)

// ref: https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/Booster.sol
interface IConvexBooster {
    function createVault(uint256 _pid) external returns (address);
    function setVeFXSProxy(address _vault, address _newproxy) external;
}