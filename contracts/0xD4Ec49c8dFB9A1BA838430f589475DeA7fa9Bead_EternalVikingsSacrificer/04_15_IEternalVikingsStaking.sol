// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IEternalVikingsStaking {
    function walletEVStakeCount(address wallet) external view returns (uint256);
    function stakeVikings(uint256[] memory vikingIds) external;
    function delegateStakeVikings(address user, uint256[] memory vikingIds) external;
}