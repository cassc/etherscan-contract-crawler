//
//  ________  ___       ___      ___
// |\   __  \|\  \     |\  \    /  /|
// \ \  \|\  \ \  \    \ \  \  /  / /
//  \ \   ____\ \  \    \ \  \/  / /
//   \ \  \___|\ \  \____\ \    / /
//    \ \__\    \ \_______\ \__/ /
//     \|__|     \|_______|\|__|/
//
// Paralverse Asami interface
//
// by @G2#5600
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IPLVAsami {
    function mint(address, uint256) external returns (uint256);
}