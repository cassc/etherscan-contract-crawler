// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './IIsekaiBattle.sol';

interface IIsekaiBattleSeeds {
    struct SeedInfo {
        uint256 statusId;
        uint256 level;
        string image;
    }

    function ISB() external view returns (IIsekaiBattle);

    function SeedInfos(uint256)
        external
        view
        returns (
            uint256 statusId,
            uint256 level,
            string calldata image
        );

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burnAdmin(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatchAdmin(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function addSeedInfo(SeedInfo memory info) external;

    function setSeedInfo(uint256 index, SeedInfo memory info) external;

    function getSeedInfosLength() external returns (uint256);
}