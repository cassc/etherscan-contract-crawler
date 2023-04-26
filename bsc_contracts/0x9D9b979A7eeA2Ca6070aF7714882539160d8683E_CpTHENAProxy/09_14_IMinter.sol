// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMinter {
    function _rewards_distributor() external view returns (address);
    function update_period() external returns (uint);
}