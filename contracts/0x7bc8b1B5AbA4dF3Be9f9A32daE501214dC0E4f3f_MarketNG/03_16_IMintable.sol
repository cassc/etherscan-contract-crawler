// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IMintable {
    function mint(address to, bytes memory data) external;
}