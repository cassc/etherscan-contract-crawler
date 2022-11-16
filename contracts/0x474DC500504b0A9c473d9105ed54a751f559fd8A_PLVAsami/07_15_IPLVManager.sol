//
//  ________  ___       ___      ___
// |\   __  \|\  \     |\  \    /  /|
// \ \  \|\  \ \  \    \ \  \  /  / /
//  \ \   ____\ \  \    \ \  \/  / /
//   \ \  \___|\ \  \____\ \    / /
//    \ \__\    \ \_______\ \__/ /
//     \|__|     \|_______|\|__|/
//
// Paralverse Asami Manager interface
//
// by @G2#5600
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IPLVManager {
    function statusOf(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}