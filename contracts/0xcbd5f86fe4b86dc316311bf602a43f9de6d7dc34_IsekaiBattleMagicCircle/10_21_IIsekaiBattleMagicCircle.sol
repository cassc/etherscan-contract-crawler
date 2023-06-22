// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IIsekaiBattleMagicCircle {
    struct MagicCircleInfo {
        string image;
    }

    function MagicCircleInfos(uint256) external view returns (string calldata image);

    function airdrop(
        address[] memory to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

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

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function addMagicCircleInfo(MagicCircleInfo memory info) external;

    function setMagicCircleInfo(uint256 index, MagicCircleInfo memory info) external;

    function getMagicCircleInfosLength() external returns (uint256);
}