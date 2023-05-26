// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.5 <= 0.7.0;

interface IPriceFeed {
    function update() external returns(uint);
    function consult() external view returns (uint);
    function updateAndConsult() external returns (uint);
}