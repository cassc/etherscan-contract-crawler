// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IHATVaultsData {
    
    function getTotalShares(uint256 _pid) external view returns (uint256 totalShares);

    function getShares(uint256 _pid, address _user) external view returns (uint256 shares);
}