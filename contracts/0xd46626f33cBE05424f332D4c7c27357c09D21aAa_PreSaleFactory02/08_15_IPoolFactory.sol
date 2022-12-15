// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1;

interface IPoolFactory {
    function getTier() external view returns (address);
}