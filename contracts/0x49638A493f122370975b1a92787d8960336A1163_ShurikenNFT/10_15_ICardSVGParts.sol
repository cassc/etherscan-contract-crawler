// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICardSVGParts {
    function getStars(uint256 count) external pure returns (bytes memory stars);
}