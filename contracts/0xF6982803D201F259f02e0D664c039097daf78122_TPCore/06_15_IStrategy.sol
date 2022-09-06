// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IStrategy {

    function farm(address erc20Token_, uint256 amount_) external returns(uint256);

    function estimateReward(address) view external returns(uint256);

    function takeReward(address to_, uint256 amount_) external;
    function takeReward(address to_) external;

    function decimals() view external returns(uint256);
    function vaultAddress() view external returns(address);
    function vaultTokenAddress() view external returns(address);
}