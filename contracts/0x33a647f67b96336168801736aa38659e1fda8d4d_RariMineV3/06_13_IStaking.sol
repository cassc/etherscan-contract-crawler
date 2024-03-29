// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

interface IStaking {
    function stake(
        address account,
        address delegate,
        uint amount,
        uint slope,
        uint cliff
    ) external returns (uint);
}