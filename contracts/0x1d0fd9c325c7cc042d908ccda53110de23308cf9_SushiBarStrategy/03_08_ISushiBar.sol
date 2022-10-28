// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

interface ISushiBar {
    function enter(uint256 _amount) external;

    function leave(uint256 _share) external;

    function totalSupply() external returns(uint256);
}