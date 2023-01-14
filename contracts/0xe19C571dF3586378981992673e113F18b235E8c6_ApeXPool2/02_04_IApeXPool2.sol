// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IApeXPool2 {
    event PausedStateChanged(bool newState);
    event Staked(address indexed token, address indexed user, uint256 accountId, uint256 amount);
    event Unstaked(address indexed token, address indexed user, address indexed to, uint256 accountId, uint256 amount);

    function apeX() external view returns (address);

    function esApeX() external view returns (address);

    function stakingAPEX(address user, uint256 accountId) external view returns (uint256);

    function stakingEsAPEX(address user, uint256 accountId) external view returns (uint256);

    function paused() external view returns (bool);

    function setPaused(bool newState) external;

    function stakeAPEX(uint256 accountId, uint256 amount) external;

    function stakeEsAPEX(uint256 accountId, uint256 amount) external;

    function unstakeAPEX(address to, uint256 accountId, uint256 amount) external;

    function unstakeEsAPEX(address to, uint256 accountId, uint256 amount) external;
}