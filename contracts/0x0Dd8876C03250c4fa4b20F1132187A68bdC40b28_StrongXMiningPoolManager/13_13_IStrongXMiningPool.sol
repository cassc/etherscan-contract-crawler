// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrongXMiningPool {
    function earned(address account) external view returns (uint rewards);
    function stake(address account, uint amount, bool isCompound) external;
    function withdraw(address account, uint amount) external;
    function claim(address account, bool compound) external;
}