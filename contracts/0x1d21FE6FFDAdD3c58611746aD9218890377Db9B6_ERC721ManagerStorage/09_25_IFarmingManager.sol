// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IFarmingManager {
    function isStaked(address erc721TokenAddress, uint256 tokenId) external view returns (bool);
}