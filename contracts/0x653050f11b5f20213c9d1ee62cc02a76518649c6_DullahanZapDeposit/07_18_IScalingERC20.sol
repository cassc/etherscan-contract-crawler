// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IScalingERC20 {
    
    function totalSupply() external view returns (uint256);
    function totalScaledSupply() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);
    function scaledBalanceOf(address user) external view returns (uint256);
    
}