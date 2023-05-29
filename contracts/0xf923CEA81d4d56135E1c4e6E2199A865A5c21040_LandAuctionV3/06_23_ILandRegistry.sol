//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILandRegistry {
    function mint(
        address user,
        int16 x,
        int16 y
    ) external;
}