// contracts/IEIP4626.sol
// SPDX-License-Identifier: MIT
// Teahouse Finance

pragma solidity ^0.8.0;

interface IWETH9 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function deposit() external payable;
    function withdraw(uint wad) external;

}