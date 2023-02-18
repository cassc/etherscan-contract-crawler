// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IOnchainArt {
    function getSVG(uint256) external view returns (string memory);
}