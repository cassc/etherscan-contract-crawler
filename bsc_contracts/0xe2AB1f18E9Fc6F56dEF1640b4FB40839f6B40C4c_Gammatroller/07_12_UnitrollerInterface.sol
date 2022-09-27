//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;


interface UnitrollerInterface  {

   
    function _setPendingImplementation(address newPendingImplementation) external returns (uint); // delete later
    function _acceptImplementation() external returns (uint);
    function admin() external view returns (address);
 
}