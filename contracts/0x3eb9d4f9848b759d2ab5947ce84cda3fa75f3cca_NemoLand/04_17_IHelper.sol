// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IHelper {
    function decoupleState(
        uint256[] memory parentState,
        uint256[] memory childState
    ) external pure returns (uint256[] memory);
}