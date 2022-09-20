// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// import "ERC20.sol";
import "ERC721.sol";
import "MythMods.sol";
import "MythCosmetic.sol";
import "MythWeapons.sol";
import "MythEquipment.sol";

contract MythDegen is ERC721 {
    address public cosmeticAddress;
    address public modsAddress;
    address public weaponsAddress;
    address public equipmentAddress;

    mapping(uint256 => stats) public degenStats;
    mapping(uint256 => equippedItems) public degenEquips;
    mapping(uint256 => cosmetics) public degenCosmetics;
    mapping(uint256 => defaultCosmetics) public degenDefaults;

    mapping(address => bool) public cosmeticWhitelist;
    mapping(address => bool) public degenWhitelist;
    mapping(address => bool) public whitelistedAddresses;

    mapping(uint256 => uint256) public defaultBackground;
    mapping(uint256 => uint256) public defaultEye;
    mapping(uint256 => uint256) public defaultMouth;
    mapping(uint256 => uint256) public defaultSkinColor;
    mapping(uint256 => uint256) public defaultNose;
    mapping(uint256 => uint256) public defaultHair;
    mapping(uint256 => mapping(uint256 => bool)) public defaultExists;

    address payable public owner;
    uint256 public tokenCount;

    struct equippedItems {
        uint256 weaponData;
        uint256 equipmentData;
        uint256 faceModData;
    }
    struct defaultCosmetics {
        uint256 background;
        uint256 bodyColor;
        uint256 nose;
        uint256 eyes;
        uint256 mouth;
        uint256 hair;
    }
    struct cosmetics {
        uint256 backgroundData;
        uint256 skinColorData;
        uint256 eyeData;
        uint256 eyeWearData;
        uint256 mouthData;
        uint256 noseData;
        uint256 hairData;
        uint256 headData;
        uint256 bodyData;
        uint256 bodyOuterData;
        uint256 chainData;
    }
    struct stats {
        uint256 coreScore;
        uint256 damageCap;
        address owner;
        bool inMission;
    }
    event defaultAdded(
        uint256 layerType,
        uint256 defaultId,
        uint256 cosmeticId
    );

    event itemEquipped(
        address owner,
        uint256 degenId,
        uint256 itemType,
        uint256 oldId,
        uint256 newId
    );

    event degenOnMission(uint256 degenId, bool onMission);

    modifier isWhitelisted() {
        require(whitelistedAddresses[msg.sender], "Not white listed");
        _;
    }
    modifier isDegenWhitelisted() {
        require(degenWhitelist[msg.sender], "Not Degen white listed");
        _;
    }
    modifier isCosmeticWhitelisted() {
        require(cosmeticWhitelist[msg.sender], "Not Cosmetic white listed");
        _;
    }

    constructor() ERC721("Myth City Degen", "MYDGN") {
        tokenCount = 1;
        owner = payable(msg.sender);
        whitelistedAddresses[msg.sender] = true;
        degenWhitelist[msg.sender] = true;
        cosmeticWhitelist[msg.sender] = true;
    }

    function setOnMission(uint256 _degenId, bool _missionSet)
        external
        isDegenWhitelisted
        returns (bool)
    {
        emit degenOnMission(_degenId, _missionSet);
        degenStats[_degenId].inMission = _missionSet;
    }

    function setAddresses(
        address _cosmetics,
        address _mods,
        address _weapons,
        address _equipments
    ) external isWhitelisted returns (bool) {
        cosmeticAddress = _cosmetics;
        modsAddress = _mods;
        weaponsAddress = _weapons;
        equipmentAddress = _equipments;
    }

    function forceTransferEquips(
        uint256 _degenId,
        address _from,
        address _to
    ) internal returns (bool) {
        equippedItems memory tempEquips = degenEquips[_degenId];
        if (tempEquips.faceModData > 0) {
            MythCityMods tempMods = MythCityMods(modsAddress);
            require(
                tempMods.overrideOwner(tempEquips.faceModData, _from, _to),
                "failed to transfer mods"
            );
        }
        if (tempEquips.weaponData > 0) {
            MythCityWeapons tempWeapons = MythCityWeapons(weaponsAddress);
            require(
                tempWeapons.overrideOwner(tempEquips.weaponData, _from, _to),
                "Failed to transfer Weapons"
            );
        }
        if (tempEquips.equipmentData > 0) {
            MythCityEquipment tempEquipment = MythCityEquipment(
                equipmentAddress
            );
            require(
                tempEquipment.overrideOwner(
                    tempEquips.equipmentData,
                    _from,
                    _to
                ),
                "Failed To transfer Equipment"
            );
        }

        MythCosmetic tempCosmeticContract = MythCosmetic(cosmeticAddress);
        require(
            tempCosmeticContract.overrideOwnerOfDegen(_degenId, _from, _to),
            "Failed To transfer Cosmetics"
        );
        return true;
    }

    function transferFrom(
        address from,
        address _to,
        uint256 _degenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _degenId),
            "ERC721: caller is not token owner or approved"
        );
        _transfer(from, _to, _degenId);
        degenStats[_degenId].owner = _to;
        require(
            forceTransferEquips(_degenId, from, _to),
            "Failed to transfer equips"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _safeTransfer(from, to, tokenId, data);
        degenStats[tokenId].owner = to;
        require(
            forceTransferEquips(tokenId, from, to),
            "Failed to transfer equips"
        );
    }

    // function withdraw() external {
    //     require(msg.sender == owner, "Not owner");
    //     owner.transfer(address(this).balance);
    // }

    function mint(
        address _to,
        uint256 _core,
        uint256 _damage,
        uint256[6] calldata _defaults
    ) public isDegenWhitelisted {
        uint256 tempCount = tokenCount;
        _mint(_to, tempCount);
        degenStats[tempCount] = stats(_core, _damage, _to, false);
        for (uint256 i = 0; i < 6; i++) {
            require(
                defaultExists[i][_defaults[i]],
                "This default cosmetic is not available"
            );
            if (i == 0) {
                degenDefaults[tempCount].background = _defaults[i];
            } else if (i == 1) {
                degenDefaults[tempCount].bodyColor = _defaults[i];
            } else if (i == 2) {
                degenDefaults[tempCount].nose = _defaults[i];
            } else if (i == 3) {
                degenDefaults[tempCount].eyes = _defaults[i];
            } else if (i == 4) {
                degenDefaults[tempCount].mouth = _defaults[i];
            } else if (i == 5) {
                degenDefaults[tempCount].hair = _defaults[i];
            }
        }
        tokenCount++;
    }

    // function changeDegenDefaults(
    //     uint256 _degenId,
    //     uint256[6] calldata _defaults
    // ) external isDegenWhitelisted {
    //     for (uint256 i = 0; i < 6; i++) {
    //         require(
    //             defaultExists[i][_defaults[i]],
    //             "This default cosmetic is not available"
    //         );
    //         if (i == 0) {
    //             degenDefaults[_degenId].background = _defaults[i];
    //         } else if (i == 1) {
    //             degenDefaults[_degenId].bodyColor = _defaults[i];
    //         } else if (i == 2) {
    //             degenDefaults[_degenId].nose = _defaults[i];
    //         } else if (i == 3) {
    //             degenDefaults[_degenId].eyes = _defaults[i];
    //         } else if (i == 4) {
    //             degenDefaults[_degenId].mouth = _defaults[i];
    //         } else if (i == 5) {
    //             degenDefaults[_degenId].hair = _defaults[i];
    //         }
    //     }
    // }

    // function burnToken(uint256 _id) external isWhitelisted {
    //     _burn(_id);
    // }

    // function upgradeDegen(
    //     uint256 _degenId,
    //     uint256 _addedCore,
    //     uint256 _addedDamage
    // ) external isDegenWhitelisted {
    //     degenStats[_degenId].coreScore += _addedCore;
    //     degenStats[_degenId].damageCap += _addedDamage;
    //     emit degenReGrade(
    //         _degenId,
    //         degenStats[_degenId].coreScore,
    //         degenStats[_degenId].damageCap
    //     );
    // }

    function reGradeDegen(
        uint256 _degenId,
        uint256 _newCore,
        uint256 _newDamage
    ) external isDegenWhitelisted returns (bool) {
        if (_newCore > 0) {
            degenStats[_degenId].coreScore = _newCore;
        }
        if (_newDamage > 0) {
            degenStats[_degenId].damageCap = _newDamage;
        }
        return true;
    }

    function getDegenEquips(uint256 _degenId)
        public
        view
        returns (equippedItems memory)
    {
        return degenEquips[_degenId];
    }

    function getDegenTotalCore(uint256 _degenId) public view returns (uint256) {
        uint256[2] memory _degenStats = getDegenStats(_degenId);
        uint256 overallCore = _degenStats[0] * 10**18;
        uint256 bonusCore = (overallCore / 100000) * _degenStats[1];
        overallCore = (overallCore + bonusCore) / 10**18;
        return overallCore;
    }

    function getDegenStats(uint256 _degenId)
        public
        view
        returns (uint256[2] memory)
    {
        uint256[2] memory tempNumbers;
        tempNumbers[0] += degenStats[_degenId].coreScore;
        tempNumbers[1] += degenStats[_degenId].damageCap;

        equippedItems memory tempDegen = degenEquips[_degenId];
        if (tempDegen.faceModData > 0) {
            MythCityMods tempMods = MythCityMods(modsAddress);
            MythCityMods.itemStat memory tempStats = tempMods.getStats(
                tempDegen.faceModData
            );
            tempNumbers[1] += tempStats.modStat;
        }
        if (tempDegen.equipmentData > 0) {
            MythCityEquipment tempEquipment = MythCityEquipment(
                equipmentAddress
            );
            MythCityEquipment.itemStat memory tempStats = tempEquipment
                .getStats(tempDegen.equipmentData);
            tempNumbers[0] += tempStats.equipmentStat;
        }
        if (tempDegen.weaponData > 0) {
            MythCityWeapons tempWeapon = MythCityWeapons(weaponsAddress);
            MythCityWeapons.itemStat memory tempStats = tempWeapon.getStats(
                tempDegen.weaponData
            );
            tempNumbers[0] += tempStats.weaponCore;
            tempNumbers[1] += tempStats.weaponDamage;
        }

        return tempNumbers;
    }

    function addCosmeticDefault(
        uint256 _layerType,
        uint256[] calldata _imageId,
        uint256[] calldata _urls
    ) external isWhitelisted {
        require(
            _imageId.length == _urls.length,
            "Lists need to be same length"
        );
        for (uint256 i = 0; i < _urls.length; i++) {
            require(_layerType >= 0 && _layerType <= 5, "");

            if (_layerType == 0) {
                defaultBackground[_imageId[i]] = _urls[i];
            } else if (_layerType == 1) {
                defaultSkinColor[_imageId[i]] = _urls[i];
            } else if (_layerType == 2) {
                defaultNose[_imageId[i]] = _urls[i];
            } else if (_layerType == 3) {
                defaultEye[_imageId[i]] = _urls[i];
            } else if (_layerType == 4) {
                defaultMouth[_imageId[i]] = _urls[i];
            } else if (_layerType == 5) {
                defaultHair[_imageId[i]] = _urls[i];
            }
            defaultExists[_layerType][_imageId[i]] = true;
            emit defaultAdded(_layerType, _imageId[i], _urls[i]);
        }
    }

    function updateWhitelist(address _address) external {
        require(msg.sender == owner, "Only owner can change the whitelist");
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
    }

    function alterCosmeticAddress(address _address) external isWhitelisted {
        cosmeticWhitelist[_address] = !cosmeticWhitelist[_address];
    }

    function alterDegenAddress(address _address) external isWhitelisted {
        degenWhitelist[_address] = !degenWhitelist[_address];
    }

    // function equipCosmetics(uint256 _degenId, uint256[] calldata _cosmeticIds)
    //     external
    // {
    //     for (uint256 i = 0; i < _cosmeticIds.length; i++) {
    //         equipCosmetic(_degenId, _cosmeticIds[i]);
    //     }
    // }

    function equipCosmetic(uint256 _degenId, uint256 _cosmeticId) public {
        require(
            degenStats[_degenId].owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        MythCosmetic tempCosmetics = MythCosmetic(cosmeticAddress);
        MythCosmetic.itemStat memory tempStats = tempCosmetics.getStats(
            _cosmeticId
        );
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the cosmetic can use it"
        );
        bool isEquipped = tempCosmetics.equipCosmetic(_cosmeticId, _degenId);
        require(isEquipped, "Cosmetic was not equipped");

        uint256 _layerId = tempStats.layerType;
        if (_layerId == 0) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].backgroundData
            );
            degenCosmetics[_degenId].backgroundData = _cosmeticId;
        } else if (_layerId == 1) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].skinColorData
            );
            degenCosmetics[_degenId].skinColorData = _cosmeticId;
        } else if (_layerId == 2) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].eyeData
            );
            degenCosmetics[_degenId].eyeData = _cosmeticId;
        } else if (_layerId == 3) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].eyeWearData
            );
            degenCosmetics[_degenId].eyeWearData = _cosmeticId;
        } else if (_layerId == 4) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].mouthData
            );
            degenCosmetics[_degenId].mouthData = _cosmeticId;
        } else if (_layerId == 5) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].noseData
            );
            degenCosmetics[_degenId].noseData = _cosmeticId;
        } else if (_layerId == 6) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].hairData
            );
            degenCosmetics[_degenId].hairData = _cosmeticId;
        } else if (_layerId == 7) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].headData
            );
            degenCosmetics[_degenId].headData = _cosmeticId;
        } else if (_layerId == 8) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].bodyData
            );
            degenCosmetics[_degenId].bodyData = _cosmeticId;
        } else if (_layerId == 9) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].bodyOuterData
            );
            degenCosmetics[_degenId].bodyOuterData = _cosmeticId;
        } else if (_layerId == 10) {
            emit itemEquipped(
                msg.sender,
                _degenId,
                0,
                _cosmeticId,
                degenCosmetics[_degenId].chainData
            );
            degenCosmetics[_degenId].chainData = _cosmeticId;
        }
    }

    // function unequipCosmetics(uint256 _degenId, uint256[] calldata _layerIds)
    //     external
    // {
    //     for (uint256 i = 0; i < _layerIds.length; i++) {
    //         unequipCosmetic(_degenId, _layerIds[i]);
    //     }
    // }

    function unequipCosmetic(uint256 _degenId, uint256 _layerId) public {
        require(
            degenStats[_degenId].owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        MythCosmetic tempCosmetics = MythCosmetic(cosmeticAddress);

        uint256 oldId = tempCosmetics.getIdOfCosmeticLayerAndDegen(
            _degenId,
            _layerId
        );
        bool isEquipped = tempCosmetics.unequipCosmetic(_degenId, _layerId);
        emit itemEquipped(msg.sender, _degenId, 0, oldId, 0);
        require(isEquipped, "Cosmetic was not un equipped");
        if (_layerId == 0) {
            delete degenCosmetics[_degenId].backgroundData;
        } else if (_layerId == 1) {
            delete degenCosmetics[_degenId].skinColorData;
        } else if (_layerId == 2) {
            delete degenCosmetics[_degenId].eyeData;
        } else if (_layerId == 3) {
            delete degenCosmetics[_degenId].eyeWearData;
        } else if (_layerId == 4) {
            delete degenCosmetics[_degenId].mouthData;
        } else if (_layerId == 5) {
            delete degenCosmetics[_degenId].noseData;
        } else if (_layerId == 6) {
            delete degenCosmetics[_degenId].hairData;
        } else if (_layerId == 7) {
            delete degenCosmetics[_degenId].headData;
        } else if (_layerId == 8) {
            delete degenCosmetics[_degenId].bodyData;
        } else if (_layerId == 9) {
            delete degenCosmetics[_degenId].bodyOuterData;
        } else if (_layerId == 10) {
            delete degenCosmetics[_degenId].chainData;
        }
    }

    function equipMod(uint256 _degenId, uint256 _modId) external {
        require(
            degenStats[_degenId].owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        require(
            !degenStats[_degenId].inMission,
            "Cant change mods when in mission"
        );
        MythCityMods tempMods = MythCityMods(modsAddress);
        MythCityMods.itemStat memory tempStats = tempMods.getStats(_modId);
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the mod can use it"
        );
        bool isEquipped = tempMods.equipMod(_modId, _degenId);
        require(isEquipped, "Mod was not equipped");
        emit itemEquipped(
            msg.sender,
            _degenId,
            2,
            degenEquips[_degenId].faceModData,
            _modId
        );
        degenEquips[_degenId].faceModData = _modId;
    }

    function unequipMod(uint256 _degenId) external {
        require(
            degenStats[_degenId].owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        require(
            !degenStats[_degenId].inMission,
            "Cant change mods when in mission"
        );
        require(degenEquips[_degenId].faceModData > 0, "No mod equipped");
        MythCityMods tempMods = MythCityMods(modsAddress);
        bool isEquipped = tempMods.unequipMod(_degenId);
        require(isEquipped, "Mod was not un equipped");
        emit itemEquipped(
            msg.sender,
            _degenId,
            2,
            degenEquips[_degenId].faceModData,
            0
        );
        delete degenEquips[_degenId].faceModData;
    }

    function equipWeapon(uint256 _degenId, uint256 _weaponId) external {
        require(
            degenStats[_degenId].owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        require(
            !degenStats[_degenId].inMission,
            "Cant change weapon when in mission"
        );
        MythCityWeapons tempWeapons = MythCityWeapons(weaponsAddress);
        MythCityWeapons.itemStat memory tempStats = tempWeapons.getStats(
            _weaponId
        );
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the weapon can use it"
        );
        bool isEquipped = tempWeapons.equipWeapon(_weaponId, _degenId);
        require(isEquipped, "Weapon was not equipped");
        emit itemEquipped(
            msg.sender,
            _degenId,
            1,
            degenEquips[_degenId].weaponData,
            _weaponId
        );
        degenEquips[_degenId].weaponData = _weaponId;
    }

    function unequipWeapon(uint256 _degenId) external {
        require(
            degenStats[_degenId].owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        require(
            !degenStats[_degenId].inMission,
            "Cant change weapon when in mission"
        );
        require(degenEquips[_degenId].weaponData > 0, "No weapon equipped");
        MythCityWeapons tempWeapons = MythCityWeapons(weaponsAddress);
        bool isEquipped = tempWeapons.unequipWeapon(_degenId);
        require(isEquipped, "Weapon was not un equipped");
        emit itemEquipped(
            msg.sender,
            _degenId,
            1,
            degenEquips[_degenId].weaponData,
            0
        );
        delete degenEquips[_degenId].weaponData;
    }

    function equipEquipment(uint256 _degenId, uint256 _equipmentId) external {
        require(
            degenStats[_degenId].owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        require(
            !degenStats[_degenId].inMission,
            "Cant change equipment when in mission"
        );
        MythCityEquipment tempEquipment = MythCityEquipment(equipmentAddress);
        MythCityEquipment.itemStat memory tempStats = tempEquipment.getStats(
            _equipmentId
        );
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the equipment can use it"
        );
        bool isEquipped = tempEquipment.equipEquipment(_equipmentId, _degenId);
        require(isEquipped, "Equipment was not equipped");
        emit itemEquipped(
            msg.sender,
            _degenId,
            3,
            degenEquips[_degenId].equipmentData,
            _equipmentId
        );
        degenEquips[_degenId].equipmentData = _equipmentId;
    }

    function unequipEquipment(uint256 _degenId) external {
        require(
            degenStats[_degenId].owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        require(
            !degenStats[_degenId].inMission,
            "Cant change equipment when in mission"
        );
        require(
            degenEquips[_degenId].equipmentData > 0,
            "No equipment equipped"
        );
        MythCityEquipment tempEquipment = MythCityEquipment(equipmentAddress);
        bool isEquipped = tempEquipment.unequipEquipment(_degenId);
        require(isEquipped, "Equipment was not un equipped");
        emit itemEquipped(
            msg.sender,
            _degenId,
            3,
            degenEquips[_degenId].equipmentData,
            0
        );
        delete degenEquips[_degenId].equipmentData;
    }

    function getWingsURL(uint256 _degenId) public view returns (string memory) {
        equippedItems memory tempEquipped = degenEquips[_degenId];
        if (tempEquipped.equipmentData == 0) {
            return "";
        }
        MythCityEquipment tempEquipment = MythCityEquipment(equipmentAddress);
        MythCityEquipment.itemStat memory tempStats = tempEquipment.getStats(
            tempEquipped.equipmentData
        );
        if (tempStats.isWings) {
            return tempEquipment.getImageURL(tempEquipped.equipmentData);
        } else {
            return "";
        }
    }

    function getDegenImage(uint256 _id)
        public
        view
        returns (string[13] memory)
    {
        string[13] memory tempList;
        tempList[0] = getBackgroundURL(_id);
        tempList[1] = getWingsURL(_id);
        tempList[2] = getSkinColorURL(_id);
        tempList[3] = getModURL(_id);
        tempList[4] = getEyeURL(_id);
        tempList[5] = getEyeWearURL(_id);
        tempList[6] = getMouthURL(_id);
        tempList[7] = getNoseURL(_id);
        tempList[8] = getHairURL(_id);
        tempList[9] = getHeadURL(_id);
        tempList[10] = getBodyURL(_id);
        tempList[11] = getBodyOuterURL(_id);
        tempList[12] = getChainURL(_id);
        return tempList;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        concatenate("Myth Degen #", Base64.uint2str(tokenId)),
                        '",',
                        '"attributes": [{"trait_type": "Degen Core Score","display_type": "number", "value": ',
                        Base64.uint2str(degenStats[tokenId].coreScore),
                        '},{"trait_type": "Degen Damage Cap","display_type": "number", "value": ',
                        Base64.uint2str(degenStats[tokenId].damageCap),
                        "},",
                        getExtraMetaData(tokenId),
                        "]",
                        ',"image_data" : "data:image/svg+xml;base64,',
                        Base64.encode(bytes(getImageLayers(tokenId))),
                        '","external_url": "mythcity.app","description":"A Myth City Degenerate. Will it go higher than the rest?"',
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getExtraMetaData(uint256 _degenId)
        public
        view
        returns (string memory)
    {
        string memory json = concatenate(getWeaponURI(_degenId), ",");
        json = concatenate(json, getModURI(_degenId));
        json = concatenate(json, ",");
        json = concatenate(json, getEquipmentURI(_degenId));
        return json;
    }

    function getModURI(uint256 _degenId) public view returns (string memory) {
        equippedItems memory tempEquips = degenEquips[_degenId];
        if (tempEquips.faceModData > 0) {
            MythCityMods tempMods = MythCityMods(modsAddress);
            string memory json = tempMods.getDegenData(tempEquips.faceModData);

            return json;
        } else {
            string
                memory modMetaString = '{"trait_type":"Mod Id","value":0},{"trait_type":"Mod Damage","value":0},{"trait_type":"Mod Image Url","value":""}';
            return modMetaString;
        }
    }

    function getEquipmentURI(uint256 _degenId)
        public
        view
        returns (string memory)
    {
        equippedItems memory tempEquips = degenEquips[_degenId];
        if (tempEquips.equipmentData > 0) {
            MythCityEquipment tempEquipment = MythCityEquipment(
                equipmentAddress
            );
            string memory json = tempEquipment.getDegenData(
                tempEquips.equipmentData
            );

            return json;
        } else {
            string
                memory equipmentMetaString = '{"trait_type":"Equipment Id","value":0},{"trait_type":"Equipment Core","value":0},{"trait_type":"Equipment Route","value":0},{"trait_type":"Equipment Image Url","value":""}';
            return equipmentMetaString;
        }
    }

    function getWeaponURI(uint256 _degenId)
        public
        view
        returns (string memory)
    {
        equippedItems memory tempEquips = degenEquips[_degenId];
        if (tempEquips.weaponData > 0) {
            MythCityWeapons tempWeapons = MythCityWeapons(weaponsAddress);
            string memory json = tempWeapons.getDegenData(
                tempEquips.weaponData
            );
            return json;
        } else {
            string
                memory weaponMetaString = '{"trait_type":"Weapon Id","value":0},{"trait_type":"Weapon Core","value":0},{"trait_type":"Weapon Damage","value":0},{"trait_type":"Weapon Type","value":0},{"trait_type":"Weapon Image Url","value":""}';
            return weaponMetaString;
        }
    }

    function getImageLayers(uint256 _id) public view returns (string memory) {
        string memory innerString = "";
        string[13] memory tempList = getDegenImage(_id);
        for (uint256 i = 0; i < 13; i++) {
            if (bytes(tempList[i]).length != bytes("").length) {
                string memory tempIMG = concatenate(
                    '<image href="',
                    tempList[i]
                );
                tempIMG = concatenate(tempIMG, ' "/>');
                innerString = concatenate(innerString, tempIMG);
            }
        }
        return
            concatenate(
                concatenate(
                    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 512 512">',
                    innerString
                ),
                "</svg>"
            );
    }

    function concatenate(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function getStats(uint256 _id) external view returns (stats memory) {
        return degenStats[_id];
    }

    function getModURL(uint256 _id) public view returns (string memory) {
        if (degenEquips[_id].faceModData == 0) {
            return "";
        }
        return
            MythCityMods(modsAddress).getImageFromId(
                degenEquips[_id].faceModData
            );
    }

    function getBackgroundURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].backgroundData == 0) {
            return
                MythCosmetic(cosmeticAddress).getUrl(
                    0,
                    defaultBackground[degenDefaults[_id].background]
                );
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].backgroundData
            );
    }

    function getNoseURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].noseData == 0) {
            return
                MythCosmetic(cosmeticAddress).getUrl(
                    5,
                    defaultNose[degenDefaults[_id].nose]
                );
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].noseData
            );
    }

    function getBodyURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].bodyData == 0) {
            return "";
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].bodyData
            );
    }

    function getBodyOuterURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].bodyOuterData == 0) {
            return "";
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].bodyOuterData
            );
    }

    function getHairURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].hairData == 0) {
            return
                MythCosmetic(cosmeticAddress).getUrl(
                    6,
                    defaultHair[degenDefaults[_id].hair]
                );
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].hairData
            );
    }

    function getHeadURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].headData == 0) {
            return "";
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].headData
            );
    }

    function getEyeURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].eyeData == 0) {
            return
                MythCosmetic(cosmeticAddress).getUrl(
                    2,
                    defaultEye[degenDefaults[_id].eyes]
                );
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].eyeData
            );
    }

    function getMouthURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].mouthData == 0) {
            return
                MythCosmetic(cosmeticAddress).getUrl(
                    4,
                    defaultMouth[degenDefaults[_id].mouth]
                );
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].mouthData
            );
    }

    function getSkinColorURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].skinColorData == 0) {
            return
                MythCosmetic(cosmeticAddress).getUrl(
                    1,
                    defaultSkinColor[degenDefaults[_id].bodyColor]
                );
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].skinColorData
            );
    }

    function getChainURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].chainData == 0) {
            return "";
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].chainData
            );
    }

    function getEyeWearURL(uint256 _id) public view returns (string memory) {
        if (degenCosmetics[_id].eyeWearData == 0) {
            return "";
        }
        return
            MythCosmetic(cosmeticAddress).getImageURL(
                degenCosmetics[_id].eyeWearData
            );
    }
}

library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function concatenate(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
// {"trait_type": "Class", "value": "Bartender"}
// {"trait_type": "Race", "value": "Ape"}
// {"trait_type": "Strength", "max_value": 100, "value": 81}
// {"trait_type": "Intelligence", "max_value": 100, "value": 73}
// {"trait_type": "Attractiveness", "max_value": 100, "value": 15}
// {"trait_type": "Tech Skill", "max_value": 100, "value": 81}
// {"trait_type": "Cool", "max_value": 100, "value": 92}
// {"trait_type": "Reward Rate", "value": 3}
// {"trait_type": "Eyes", "value": "Suspicious"}
// {"trait_type": "Ability", "value": "Dead Eye"}
// {"trait_type": "Location", "value": "Citadel Tower"}
// {"trait_type": "Additional Item", "value": "Wooden Cup"}
// {"trait_type": "Weapon", "value": "None"}
// {"trait_type": "Vehicle", "value": "Car 6"}
// {"trait_type": "Apparel", "value": "Suit 1"}
// {"trait_type": "Helm", "value": "Pilot Helm"}
// {"trait_type": "Gender", "value": "Male"}