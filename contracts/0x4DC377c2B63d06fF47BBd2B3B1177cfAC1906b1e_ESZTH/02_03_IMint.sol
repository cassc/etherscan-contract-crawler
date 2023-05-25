// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
 
interface IMint {
    function mint(address to, uint256 amount) external;
}