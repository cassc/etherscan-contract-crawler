// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "MythMods.sol";
import "MythWeapons.sol";
import "MythEquipment.sol";
import "MythCosmetic.sol";
import "MythEngrams.sol";
import "MythToken.sol";

contract MythCityNFTShop {
    address payable public owner;
    address public modsAddress;
    address public weaponsAddress;
    address public equipmentAddress;
    address public cosmeticAddress;
    address public engramAddress;

    address payable public mythralAddress;

    mapping(uint256 => modShopItem) public modShopItems;
    mapping(uint256 => weaponShopItem) public weaponShopItems;
    mapping(uint256 => equipmentShopItem) public equipmentShopItems;
    mapping(uint256 => cosmeticShopItem) public cosmeticShopItems;
    mapping(uint256 => engramShopItem) public engramShopItems;

    struct modShopItem {
        uint256 imageId;
        uint256 itemCost;
        uint256 itemStat;
        uint256 nameId;
        uint256 mythCost;
        uint256 limit;
    }
    struct engramShopItem {
        address tableAddress;
        uint256 itemCost;
        uint256 engramTier;
        uint256 mythCost;
        uint256 limit;
    }
    struct equipmentShopItem {
        uint256 imageId;
        uint256 itemCost;
        uint256 itemStat;
        uint256 routeType;
        uint256 nameId;
        uint256 mythCost;
        uint256 limit;
    }
    struct weaponShopItem {
        uint256 imageId;
        uint256 itemCost;
        uint256 core;
        uint256 damage;
        uint256 weaponType;
        uint256 nameId;
        uint256 mythCost;
        uint256 limit;
    }
    struct cosmeticShopItem {
        uint256 layerId;
        uint256 imageId;
        uint256 itemCost;
        uint256 nameId;
        uint256 mythCost;
        uint256 limit;
    }
    event modShopAdded(
        uint256 shopItemId,
        uint256 imageId,
        uint256 itemCost,
        uint256 itemStat,
        uint256 nameId,
        uint256 mythCost,
        uint256 limit
    );
    event engramShopAdded(
        uint256 shopItemId,
        address tableAddress,
        uint256 itemCost,
        uint256 engramTier,
        uint256 mythCost,
        uint256 limit
    );
    event equipmentShopAdded(
        uint256 shopItemId,
        uint256 imageId,
        uint256 itemCost,
        uint256 itemStat,
        uint256 routeType,
        uint256 nameId,
        uint256 mythCost,
        uint256 limit
    );
    event weaponShopAdded(
        uint256 shopItemId,
        uint256 imageId,
        uint256 itemCost,
        uint256 itemStat,
        uint256 itemDamage,
        uint256 weaponType,
        uint256 nameId,
        uint256 mythCost,
        uint256 limit
    );
    event cosmeticShopAdded(
        uint256 shopItemId,
        uint256 layerId,
        uint256 imageId,
        uint256 itemCost,
        uint256 nameId,
        uint256 mythCost,
        uint256 limit
    );
    event modShopRemoved(uint256 shopItemId);
    event weaponShopRemoved(uint256 shopItemId);
    event equipmentShopRemoved(uint256 shopItemId);
    event cosmeticShopRemoved(uint256 shopItemId);
    event engramShopRemoved(uint256 shopItemId);

    event modShopBought(uint256 shopItemId, uint256 amountLeft);
    event weaponShopBought(uint256 shopItemId, uint256 amountLeft);
    event equipmentShopBought(uint256 shopItemId, uint256 amountLeft);
    event cosmeticShopBought(uint256 shopItemId, uint256 amountLeft);
    event engramShopBought(uint256 shopItemId, uint256 amountLeft);

    constructor(
        address _mods,
        address _weapons,
        address _equipment,
        address _cosmetic,
        address _mythral
    ) {
        owner = payable(msg.sender);
        modsAddress = _mods;
        weaponsAddress = _weapons;
        equipmentAddress = _equipment;
        cosmeticAddress = _cosmetic;
        mythralAddress = payable(_mythral);
    }

    function addModShopItem(
        uint256 _modId,
        uint256 _modImageId,
        uint256 _cost,
        uint256 _stat,
        uint256 nameId,
        uint256 _mythCost,
        uint256 _limit
    ) external {
        require(msg.sender == owner, "only owner");
        modShopItems[_modId] = modShopItem(
            _modImageId,
            _cost,
            _stat,
            nameId,
            _mythCost,
            _limit
        );
        emit modShopAdded(
            _modId,
            _modImageId,
            _cost,
            _stat,
            nameId,
            _mythCost,
            _limit
        );
    }

    function addEngramShopItem(
        uint256 _engramId,
        address _tableAddress,
        uint256 _cost,
        uint256 _tier,
        uint256 _mythCost,
        uint256 _limit
    ) external {
        require(msg.sender == owner, "only owner");
        engramShopItems[_engramId] = engramShopItem(
            _tableAddress,
            _cost,
            _tier,
            _mythCost,
            _limit
        );
        emit engramShopAdded(
            _engramId,
            _tableAddress,
            _cost,
            _tier,
            _mythCost,
            _limit
        );
    }

    function addCosmeticShopItem(
        uint256 _cosmeticId,
        uint256 _layerId,
        uint256 _imageId,
        uint256 _itemCost,
        uint256 _nameId,
        uint256 _mythCost,
        uint256 _limit
    ) external {
        require(msg.sender == owner, "only owner");
        cosmeticShopItems[_cosmeticId] = cosmeticShopItem(
            _layerId,
            _imageId,
            _itemCost,
            _nameId,
            _mythCost,
            _limit
        );
        emit cosmeticShopAdded(
            _cosmeticId,
            _layerId,
            _imageId,
            _itemCost,
            _nameId,
            _mythCost,
            _limit
        );
    }

    function addEquipmentShopItem(
        uint256 _equipmentId,
        uint256 _equipmentImageId,
        uint256 _cost,
        uint256 _stat,
        uint256 _route,
        uint256 nameId,
        uint256 _mythCost,
        uint256 _limit
    ) external {
        require(msg.sender == owner, "only owner");
        equipmentShopItems[_equipmentId] = equipmentShopItem(
            _equipmentImageId,
            _cost,
            _stat,
            _route,
            nameId,
            _mythCost,
            _limit
        );
        emit equipmentShopAdded(
            _equipmentId,
            _equipmentImageId,
            _cost,
            _stat,
            _route,
            nameId,
            _mythCost,
            _limit
        );
    }

    function addWeaponShopItem(
        uint256 _weaponId,
        uint256 _weaponImageId,
        uint256 _cost,
        uint256 _core,
        uint256 _damage,
        uint256 _weaponType,
        uint256 nameId,
        uint256 _mythCost,
        uint256 _limit
    ) external {
        require(msg.sender == owner, "only owner");
        weaponShopItems[_weaponId] = weaponShopItem(
            _weaponImageId,
            _cost,
            _core,
            _damage,
            _weaponType,
            nameId,
            _mythCost,
            _limit
        );
        emit weaponShopAdded(
            _weaponId,
            _weaponImageId,
            _cost,
            _core,
            _damage,
            _weaponType,
            nameId,
            _mythCost,
            _limit
        );
    }

    function buyModMythral(uint256 _modId) external {
        modShopItem memory tempItem = modShopItems[_modId];
        MythToken mythralContract = MythToken(mythralAddress);
        mythralContract.burnTokens(tempItem.mythCost, msg.sender);
        require(tempItem.limit > 0, "Limit Reached");
        modShopItems[_modId].limit -= 1;
        MythCityMods tempMod = MythCityMods(modsAddress);
        require(
            tempMod.mint(
                msg.sender,
                tempItem.imageId,
                tempItem.itemStat,
                tempItem.nameId
            ),
            "Failed to mint"
        );
        emit modShopBought(_modId, modShopItems[_modId].limit);
    }

    function buyCosmeticMythral(uint256 _cosmeticId) external {
        cosmeticShopItem memory tempItem = cosmeticShopItems[_cosmeticId];
        MythToken mythralContract = MythToken(mythralAddress);
        mythralContract.burnTokens(tempItem.mythCost, msg.sender);
        require(tempItem.limit > 0, "Limit Reached");
        cosmeticShopItems[_cosmeticId].limit -= 1;
        MythCosmetic tempCosmetic = MythCosmetic(cosmeticAddress);
        require(
            tempCosmetic.mint(
                msg.sender,
                tempItem.imageId,
                tempItem.layerId,
                tempItem.nameId
            ),
            "Failed to mint"
        );
        emit cosmeticShopBought(
            _cosmeticId,
            cosmeticShopItems[_cosmeticId].limit
        );
    }

    function buyEquipmentMythral(uint256 _equipmentId) external {
        equipmentShopItem memory tempItem = equipmentShopItems[_equipmentId];
        MythToken mythralContract = MythToken(mythralAddress);
        mythralContract.burnTokens(tempItem.mythCost, msg.sender);
        require(tempItem.limit > 0, "Limit Reached");
        equipmentShopItems[_equipmentId].limit -= 1;
        MythCityEquipment tempEquipment = MythCityEquipment(equipmentAddress);
        require(
            tempEquipment.mint(
                tempItem.routeType == 0 ? true : false,
                msg.sender,
                tempItem.imageId,
                tempItem.itemStat,
                tempItem.routeType,
                tempItem.nameId
            ),
            "Failed to mint"
        );
        emit equipmentShopBought(
            _equipmentId,
            equipmentShopItems[_equipmentId].limit
        );
    }

    function buyWeaponMythral(uint256 _weaponId) external {
        weaponShopItem memory tempItem = weaponShopItems[_weaponId];
        MythToken mythralContract = MythToken(mythralAddress);
        mythralContract.burnTokens(tempItem.mythCost, msg.sender);
        require(tempItem.limit > 0, "Limit Reached");
        weaponShopItems[_weaponId].limit -= 1;
        MythCityWeapons tempWeapons = MythCityWeapons(weaponsAddress);
        bool isMinted = tempWeapons.mint(
            msg.sender,
            tempItem.imageId,
            tempItem.core,
            tempItem.damage,
            tempItem.weaponType,
            tempItem.nameId
        );
        require(isMinted, "Failed to mint");
        emit weaponShopBought(_weaponId, weaponShopItems[_weaponId].limit);
    }

    function setAddresses(
        address _modsAddress,
        address _weaponsAddress,
        address _equipmentAddress,
        address _cosmeticAddress,
        address _engramAddress
    ) external {
        require(msg.sender == owner, "only owner");
        if (_modsAddress != address(0)) {
            modsAddress = _modsAddress;
        }
        if (_weaponsAddress != address(0)) {
            weaponsAddress = _weaponsAddress;
        }
        if (_equipmentAddress != address(0)) {
            equipmentAddress = _equipmentAddress;
        }
        if (_cosmeticAddress != address(0)) {
            cosmeticAddress = _cosmeticAddress;
        }
        if (_engramAddress != address(0)) {
            engramAddress = _engramAddress;
        }
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
    }
}