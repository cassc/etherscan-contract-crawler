// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IFoundFund {
    function payeeOf(uint fund) external view returns (address);

    function rewardOf(uint fund) external view returns (uint16);

    function isActive(uint fund) external view returns (bool);

    function credit(address account, uint fund, uint note, uint amount) external;
}