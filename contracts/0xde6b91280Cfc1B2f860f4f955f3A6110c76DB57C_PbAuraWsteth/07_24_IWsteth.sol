// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IWsteth {
    function getStETHByWstETH(uint amount) external view returns (uint);
}