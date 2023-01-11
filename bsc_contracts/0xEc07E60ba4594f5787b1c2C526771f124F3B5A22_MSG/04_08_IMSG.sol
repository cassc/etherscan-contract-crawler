// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMSG {
    function addMinter(address minter) external;
    function removeMinter(address minter) external;
    function mintToken(address receiver, uint256 amount) external;
    function burnToken(uint256 amount) external;
}