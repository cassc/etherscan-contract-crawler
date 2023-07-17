// SPDX-License-Identifier: GPL-3.0

/// Based on Nouns

pragma solidity ^0.8.6;

import {iSeeder} from "./iSeeder.sol";

interface iDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(
        uint256 tokenId,
        iSeeder.Seed memory seed,
        bool burned
    ) external view returns (string memory);

    function dataURI(
        uint256 tokenId,
        iSeeder.Seed memory seed,
        bool burned
    ) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function skyCount() external view returns (uint256);

    function pepeCount() external view returns (uint256);

    function altitudesCount() external view returns (uint256);
}