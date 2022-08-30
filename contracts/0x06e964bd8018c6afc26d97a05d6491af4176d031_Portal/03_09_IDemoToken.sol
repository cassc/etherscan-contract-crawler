// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IDemoToken {
    function mint(address _addr, uint _amount) external; 
    function burn(address _addr, uint _amount) external;
}