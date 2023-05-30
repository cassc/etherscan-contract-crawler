// SPDX-License-Identifier: MIT
// Author: Club Cards
// Developed by Max J. Rux

pragma solidity ^0.8.7;

interface IClubCards {
    function mintCard(uint256 numMints, uint256 waveId) external payable;

    function whitelistMint(
        uint256 numMints,
        uint256 waveId,
        uint256 nonce,
        uint256 timestamp,
        bytes calldata signature
    ) external payable;

    function claim(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 nonce,
        uint256 timestamp,
        bytes memory signature
    ) external payable;

    function allStatus() external view returns (bool);

    function uri(uint256 id) external view returns (string memory);

    function contractURI() external view returns (string memory);
}