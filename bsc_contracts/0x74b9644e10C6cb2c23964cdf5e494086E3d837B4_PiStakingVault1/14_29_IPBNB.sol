// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
import "./IWETH.sol";

interface IPBNB is IWETH
{
    
    function FEE() external view returns (uint256);
    function FEE_ADDRESS() external view returns (address);
    function isIgnored(address _ignoredAddress) external view returns (bool);
    
}