// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './IIsekaiBattle.sol';
import './IISBStaticData.sol';

interface IIsekaiBattleArmor {
    struct ArmorInfo {
        IISBStaticData.ArmorType armorType;
        uint256 level;
        string image;
    }

    function ISB() external view returns (IIsekaiBattle);

    function ArmorInfos(uint256)
        external
        view
        returns (
            IISBStaticData.ArmorType armorType,
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

    function addArmorInfo(ArmorInfo memory info) external;

    function setArmorInfo(uint256 index, ArmorInfo memory info) external;

    function getArmorInfosLength() external returns (uint256);
}