//
//  ________  ___       ___      ___
// |\   __  \|\  \     |\  \    /  /|
// \ \  \|\  \ \  \    \ \  \  /  / /
//  \ \   ____\ \  \    \ \  \/  / /
//   \ \  \___|\ \  \____\ \    / /
//    \ \__\    \ \_______\ \__/ /
//     \|__|     \|_______|\|__|/
//
// Paralverse Asami Metadata interface
//
// by @G2#5600
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IPLVAsamiMeta {
    function build(
        address,
        uint256,
        uint256
    ) external;

    function rebuild(address, uint256) external;

    function setName(uint256, string memory) external;

    function metaOf(uint256) external view returns (uint256);
}