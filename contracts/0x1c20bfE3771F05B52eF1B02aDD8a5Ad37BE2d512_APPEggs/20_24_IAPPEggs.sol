// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAPPEggs {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}