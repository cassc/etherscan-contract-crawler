// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IStaminaInfo {
    function kubzCanTransfer(uint256 tokenId) external view returns (bool);

    function kzgCanTransfer(uint256 tokenId) external view returns (bool);
}