// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRandom {
    function seed(uint256 initQty) external;

    function getRand() external view returns (uint256);

    function getLuckyDraws(
        uint32 loops,
        uint32[6] calldata breakPoints,
        uint32 minLevel,
        uint32 maxLevel
    ) external view returns (uint32[5] memory);
}