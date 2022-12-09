// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './IIsekaiBattle.sol';
import './IISBStaticData.sol';

interface IIsekaiBattleWeapon {
    struct WeaponInfo {
        IISBStaticData.WeaponType weaponType;
        uint256 level;
        string image;
    }

    function ISB() external view returns (IIsekaiBattle);

    function WeaponInfos(uint256)
        external
        view
        returns (
            IISBStaticData.WeaponType weaponType,
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

    function addWeaponInfo(WeaponInfo memory info) external;

    function setWeaponInfo(uint256 index, WeaponInfo memory info) external;

    function getWeaponInfosLength() external returns (uint256);
}