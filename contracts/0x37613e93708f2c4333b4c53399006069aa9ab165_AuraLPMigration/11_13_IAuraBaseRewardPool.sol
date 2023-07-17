//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuraBaseRewardPool {
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    function asset() external view returns (address);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    // IERC20
    function allowance(address owner, address spender) external view returns (uint256);
}