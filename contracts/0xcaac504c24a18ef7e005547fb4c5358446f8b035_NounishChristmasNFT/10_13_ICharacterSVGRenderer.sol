// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICharacterSVGRenderer {
    function characterSVG(uint8 character) external pure returns (string memory);
}