// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReleaseManager {
    
    function initialize() external;


    function registerInstance(address instanceAddress) external;
    //function checkInstance(address addr) external view returns(bool);
    
}