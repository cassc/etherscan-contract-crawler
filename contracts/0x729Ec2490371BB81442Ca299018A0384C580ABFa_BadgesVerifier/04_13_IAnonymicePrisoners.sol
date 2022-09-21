// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IAnonymicePrisoners {
    function getPrisonerGenesisId(uint256 tokenId) external view returns (uint256);
}