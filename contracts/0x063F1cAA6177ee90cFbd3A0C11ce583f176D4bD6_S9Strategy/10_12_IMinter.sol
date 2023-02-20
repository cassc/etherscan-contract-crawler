pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IMinter {
    function rate() external view returns(uint rate);
    
    function mint(address toGauge) external;
}