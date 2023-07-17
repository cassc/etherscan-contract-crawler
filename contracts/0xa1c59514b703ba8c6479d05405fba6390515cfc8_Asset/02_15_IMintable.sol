// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMintable {
    function mintFor(
        address to,
        uint256 id,
        bytes calldata blueprint
    ) external;
}