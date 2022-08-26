// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMinter {
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
    event Minted(address indexed recipient, address indexed gaugeAddr, uint256 indexed tokenId, uint256 minted);

    function token() external view returns (address);

    function controller() external view returns (address);

    function initialSupply() external view returns (uint256);

    function initialRate() external view returns (uint256);

    function rateReductionTime() external view returns (uint256);

    function rateReductionCoefficient() external view returns (uint256);

    function miningEpoch() external view returns (int128);

    function startEpochTime() external view returns (uint256);

    function rate() external view returns (uint256);

    function availableSupply() external view returns (uint256);

    function mintableInTimeframe(uint256 start, uint256 end) external view returns (uint256);

    function minted(
        address gaugeAddr,
        uint256 tokenId,
        address user
    ) external view returns (uint256);

    function updateMiningParameters() external;

    function startEpochTimeWrite() external returns (uint256);

    function futureEpochTimeWrite() external returns (uint256);

    function mint(address gaugeAddr, uint256 tokenId) external;
}