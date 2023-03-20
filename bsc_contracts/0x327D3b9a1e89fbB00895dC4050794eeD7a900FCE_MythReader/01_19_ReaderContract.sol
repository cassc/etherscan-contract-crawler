// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "Degen.sol";

contract MythReader {
    address payable public owner;
    address public degensAddress;
    address public weaponsAddress;
    address public modsAddress;
    address public equipmentsAddress;
    address public cosmeticsAddress;

    constructor(
        address degen,
        address weapon,
        address mod,
        address equipment,
        address cosmetics
    ) {
        owner = payable(msg.sender);
        degensAddress = degen;
        weaponsAddress = weapon;
        modsAddress = mod;
        equipmentsAddress = equipment;
        cosmeticsAddress = cosmetics;
    }

    function getUsersDegens(
        address account
    ) public view returns (uint256[] memory) {
        MythDegen mythDegen = MythDegen(degensAddress);
        uint256 tokenCount = mythDegen.tokenCount();
        uint256 userCount = mythDegen.balanceOf(account);
        uint256[] memory uriList = new uint256[](userCount);
        uint256 arrayCounter = 0;
        for (uint256 i = 1; i < tokenCount; i++) {
            if (userCount == 0) {
                return uriList;
            }
            if (mythDegen.ownerOf(i) == account) {
                uriList[arrayCounter] = i;
                arrayCounter += 1;
                userCount -= 1;
            }
        }
        return uriList;
    }

    function getUsersMods(
        address account
    ) public view returns (uint256[] memory) {
        MythCityMods mythMods = MythCityMods(modsAddress);
        uint256 tokenCount = mythMods.tokenCount();
        uint256 userCount = mythMods.balanceOf(account);
        uint256[] memory uriList = new uint256[](userCount);
        uint256 arrayCounter = 0;
        for (uint256 i = 1; i < tokenCount; i++) {
            if (userCount == 0) {
                return uriList;
            }
            if (mythMods.ownerOf(i) == account) {
                uriList[arrayCounter] = i;
                arrayCounter += 1;
                userCount -= 1;
            }
        }
        return uriList;
    }

    function getUsersWeapons(
        address account
    ) public view returns (uint256[] memory) {
        MythCityWeapons mythWeapons = MythCityWeapons(modsAddress);
        uint256 tokenCount = mythWeapons.tokenCount();
        uint256 userCount = mythWeapons.balanceOf(account);
        uint256[] memory uriList = new uint256[](userCount);
        uint256 arrayCounter = 0;
        for (uint256 i = 1; i < tokenCount; i++) {
            if (userCount == 0) {
                return uriList;
            }
            if (mythWeapons.ownerOf(i) == account) {
                uriList[arrayCounter] = i;
                arrayCounter += 1;
                userCount -= 1;
            }
        }
        return uriList;
    }

    function getUsersEquipment(
        address account
    ) public view returns (uint256[] memory) {
        MythCityEquipment mythEquipment = MythCityEquipment(equipmentsAddress);
        uint256 tokenCount = mythEquipment.tokenCount();
        uint256 userCount = mythEquipment.balanceOf(account);
        uint256[] memory uriList = new uint256[](userCount);
        uint256 arrayCounter = 0;
        for (uint256 i = 1; i < tokenCount; i++) {
            if (userCount == 0) {
                return uriList;
            }
            if (mythEquipment.ownerOf(i) == account) {
                uriList[arrayCounter] = i;
                arrayCounter += 1;
                userCount -= 1;
            }
        }
        return uriList;
    }

    function getUsersCosmetics(
        address account
    ) public view returns (uint256[] memory) {
        MythCosmetic mythCosmetic = MythCosmetic(cosmeticsAddress);
        uint256 tokenCount = mythCosmetic.tokenCount();
        uint256 userCount = mythCosmetic.balanceOf(account);
        uint256[] memory uriList = new uint256[](userCount);
        uint256 arrayCounter = 0;
        for (uint256 i = 1; i < tokenCount; i++) {
            if (userCount == 0) {
                return uriList;
            }
            if (mythCosmetic.ownerOf(i) == account) {
                uriList[arrayCounter] = i;
                arrayCounter += 1;
                userCount -= 1;
            }
        }
        return uriList;
    }
}