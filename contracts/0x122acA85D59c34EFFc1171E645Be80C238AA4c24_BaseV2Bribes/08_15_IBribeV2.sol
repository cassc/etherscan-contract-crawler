// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IRegistry} from "./IRegistry.sol";

interface IBribeV2 {
    function registry() external view returns (IRegistry);

    function notifyRewardAmount(address token, uint256 amount) external;

    function left(address token) external view returns (uint256);

    function _deposit(uint256 amount, address tokenId) external;

    function _withdraw(uint256 amount, address tokenId) external;

    function getRewardForOwner(address tokenId, address[] memory tokens)
        external;

    event Deposit(address indexed from, address tokenId, uint256 amount);
    event Withdraw(address indexed from, address tokenId, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
}