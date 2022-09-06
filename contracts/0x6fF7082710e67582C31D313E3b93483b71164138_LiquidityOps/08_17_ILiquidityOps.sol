pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/temple-frax/ILiquidityOps.sol)

interface ILiquidityOps {
    function allTranches() external view returns (address[] memory);
    function getRewards(address[] calldata _tranches) external;
    function harvestRewards() external;
}