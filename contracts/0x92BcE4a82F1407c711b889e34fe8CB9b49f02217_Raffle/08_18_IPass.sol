// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPass {
    function redeem(
        address account,
        uint256 id,
        uint256 value
    ) external;
}