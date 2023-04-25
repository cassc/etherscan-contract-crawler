// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.13;

interface IBasicToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}