// SPDX-License-Identifier: MIT
pragma solidity >=0.6.9;

interface ITransitAllowed {
    
    function checkAllowed(uint8 flag, address caller, bytes4 fun) external view returns (bool);

}