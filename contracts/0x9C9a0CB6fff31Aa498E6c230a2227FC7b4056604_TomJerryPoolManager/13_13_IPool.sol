// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
    function getReward(address _user) external view returns (uint);
    function claim(address _account) external;
    function distribute() external;
}