// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Randomness.sol";

interface ISeeder {
    event Requested(address indexed origin, uint256 indexed identifier);

    event Seeded(bytes32 identifier, uint256 randomness);

    function getIdReferenceCount(
        bytes32 randomnessId,
        address origin,
        uint256 startIdx
    ) external view returns (uint256);

    function getIdentifiers(
        bytes32 randomnessId,
        address origin,
        uint256 startIdx,
        uint256 count
    ) external view returns (uint256[] memory);

    function requestSeed(uint256 identifier) external;

    function getSeed(address origin, uint256 identifier)
        external
        view
        returns (uint256);

    function getSeedSafe(address origin, uint256 identifier)
        external
        view
        returns (uint256);

    function executeRequestMulti() external;

    function isSeeded(address origin, uint256 identifier)
        external
        view
        returns (bool);

    function setFee(uint256 fee) external;

    function getFee() external view returns (uint256);

    function getData(address origin, uint256 identifier)
        external
        view
        returns (Randomness.SeedData memory);
}