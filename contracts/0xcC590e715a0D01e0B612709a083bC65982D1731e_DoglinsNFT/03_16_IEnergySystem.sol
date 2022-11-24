// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnergySystem {
    function startEarning(address from) external;
    function stopEarning(address from) external;
    function boostBatch(uint[] calldata tokenIds) external;
    function unboostBatch(uint[] calldata tokenIds) external;
    function startTime(uint[] calldata tokenIds) external;
    function boost(uint tokenId) external;
    function unboost(uint tokenId) external;
    function boosted(uint tokenId) external returns (bool);
}