// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IFarming {
    function update(uint256 pid, address owner) external;
}