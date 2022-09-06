//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

interface IEyeDescriptions {
    function getDescription(
        uint256,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory
    ) external pure returns (string memory);
}