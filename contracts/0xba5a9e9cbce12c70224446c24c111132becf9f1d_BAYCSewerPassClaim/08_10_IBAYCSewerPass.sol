// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBAYCSewerPass {
    function mintSewerPass(
        address to,
        uint256 mintdata
    ) external returns (uint256);
}