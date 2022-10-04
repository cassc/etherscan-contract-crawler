// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ICommunity {
    
    function initialize(
        address implState,
        address implView,
        address hook, 
        address costManager, 
        string memory name, 
        string memory symbol
    ) external;
    
    function addressesCount(uint8 roleIndex) external view returns(uint256);
    function getRoles(address member)external view returns(uint8[] memory);
    function getAddresses(uint8 rolesIndex) external view returns(address[] memory);
}