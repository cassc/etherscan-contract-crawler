// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ISegments {
    function renderSvg(string memory word, uint256[3] memory rgbs) external pure returns (string memory svg);
}