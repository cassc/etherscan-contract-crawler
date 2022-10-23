// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBooster {
    function deposit(uint _pid, uint _amount, bool _stake) external;

    function withdraw(uint _pid, uint _amount) external;

    function poolInfo(uint _pid) external view returns (address, address, address, address);
}