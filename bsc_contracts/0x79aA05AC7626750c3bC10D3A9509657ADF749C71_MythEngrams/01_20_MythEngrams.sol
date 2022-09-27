// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ERC721.sol";
import "ERC20.sol";
import "Degen.sol";
import "EngramTable.sol";

contract MythEngrams is ERC721 {
    address public owner;
    uint256 public tokenCount;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => bool) public resolverAddresses;
    mapping(address => bool) public availableTableAddresses;
    mapping(address => string) public tableAddressImageUrl;
    mapping(uint256 => bool) public resolvedBlocks;
    mapping(uint256 => bool) public pendingDegenIds;
    mapping(uint256 => bool) public pendingWeaponIds;
    mapping(uint256 => bool) public pendingModIds;
    mapping(uint256 => bool) public pendingEquipmentIds;
    mapping(uint256 => uint256) public blockNumberCount;

    mapping(uint256 => mapping(uint256 => uint256)) public blockToCountToId;
    address public weaponAddress;
    address public modAddress;
    address public equipmentAddress;
    address public degenAddress;
    mapping(uint256 => itemStat) public engramStats;
    event whitelistAdded(address whitelistedAddress, bool isWhitelisted);
    event engramMinted(
        address owner,
        uint256 engramId,
        uint256 engramTier,
        address engramTable
    );
    event blockResolved(uint256 blockNumber);
    event engramActivated(
        uint256 engramId,
        uint256 initializationBlock,
        address owner
    );
    event engramUpgraded(
        address owner,
        uint256 engramId,
        uint256 degenId,
        uint256 tokenId,
        uint256 tokenType,
        uint256 oldStat,
        uint256 newStat
    );

    event engramTableChanged(
        address tableAddress,
        bool tableState,
        string imageURL
    );
    enum EngramState {
        OWNED,
        INITIALIZED,
        RESOLVED,
        UPGRADED
    }
    struct itemStat {
        address owner;
        address engramTable;
        EngramState engramState;
        uint256 engramTier;
        uint256 idOfItemToUpgrade;
        uint256 typeOfItemToUpgrade;
        uint256 statOfItemToUpgrade;
        uint256 statOfItemAfterUpgrade;
        uint256 initializationBlock;
        uint256 numberRolled;
        uint256 valueOfStatWhenUpgraded;
        bytes32 resolutionSeed;
    }
    //The engram needs to know which item type (weapon, mod, equipment, degen)
    //the engram needs to know which stat( core or damage )

    modifier isWhitelisted() {
        require(
            whitelistedAddresses[msg.sender] || msg.sender == owner,
            "Not white listed"
        );
        _;
    }

    constructor(
        address _weaponAddress,
        address _modAddress,
        address _equipmentAddress,
        address _degenAddress
    ) ERC721("Myth City Engrams", "MYTHGRAM") {
        owner = msg.sender;
        whitelistedAddresses[msg.sender] = true;
        resolverAddresses[msg.sender] = true;
        weaponAddress = _weaponAddress;
        modAddress = _modAddress;
        equipmentAddress = _equipmentAddress;
        degenAddress = _degenAddress;
    }

    function setAddresses(
        address _modsAddress,
        address _weaponsAddress,
        address _equipmentAddress,
        address _degenAddress
    ) external {
        require(msg.sender == owner, "only owner");
        if (_modsAddress != address(0)) {
            modAddress = _modsAddress;
        }
        if (_weaponsAddress != address(0)) {
            weaponAddress = _weaponsAddress;
        }
        if (_equipmentAddress != address(0)) {
            equipmentAddress = _equipmentAddress;
        }
        if (_degenAddress != address(0)) {
            degenAddress = _degenAddress;
        }
    }

    function changeEngramTable(
        address _tableAddress,
        bool _state,
        string memory _imageUrl
    ) external {
        require(
            whitelistedAddresses[msg.sender],
            "Only whitelisted addresses can change engram tables"
        );
        availableTableAddresses[_tableAddress] = _state;
        tableAddressImageUrl[_tableAddress] = _imageUrl;
        emit engramTableChanged(_tableAddress, _state, _imageUrl);
    }

    function alterWhitelist(address _address) external isWhitelisted {
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
        emit whitelistAdded(_address, whitelistedAddresses[_address]);
    }

    function alterResolver(address _address) external isWhitelisted {
        resolverAddresses[_address] = !resolverAddresses[_address];
    }

    function transfer(uint256 _engramId, address _to) external {
        require(
            engramStats[_engramId].owner == msg.sender,
            "Only the owner can transfer with this method"
        );
        require(
            engramStats[_engramId].engramState == EngramState.OWNED,
            "Cannot transfer when used"
        );
        _transfer(msg.sender, _to, _engramId);
        engramStats[_engramId].owner = _to;
    }

    function transferFrom(
        address from,
        address _to,
        uint256 _engramId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _engramId),
            "ERC721: caller is not token owner or approved"
        );
        require(
            engramStats[_engramId].engramState == EngramState.OWNED,
            "Cannot transfer when used"
        );
        _transfer(from, _to, _engramId);
        engramStats[_engramId].owner = _to;
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
        require(
            engramStats[tokenId].engramState == EngramState.OWNED,
            "Cannot transfer when used"
        );
        _safeTransfer(from, to, tokenId, data);
        engramStats[tokenId].owner = to;
    }

    function mint(
        address _to,
        uint256 _engramTier,
        address _engramTable
    ) external isWhitelisted returns (bool) {
        uint256 tempCount = tokenCount;
        require(
            availableTableAddresses[_engramTable],
            "This table address is not available."
        );
        _mint(_to, tempCount);
        engramStats[tempCount].owner = _to;
        engramStats[tempCount].engramTier = _engramTier;
        engramStats[tempCount].engramTable = _engramTable;
        emit engramMinted(_to, tempCount, _engramTier, _engramTable);
        tokenCount++;
        return true;
    }

    function activateWeapon(
        uint256 _engramId,
        uint256 _upgradeStat,
        uint256 _idOfItem
    ) external {
        require(_upgradeStat >= 1 && _upgradeStat <= 2, "Select correct stat");
        require(
            !pendingWeaponIds[_idOfItem],
            "Please wait for previous upgrade to resolve."
        );
        pendingWeaponIds[_idOfItem] = true;
        itemStat memory tempStats = engramStats[_engramId];
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the engram can activate it"
        );
        require(
            tempStats.engramState == EngramState.OWNED,
            "Already Activated"
        );
        MythCityWeapons tempContract = MythCityWeapons(weaponAddress);
        MythCityWeapons.itemStat memory tempWeaponStat = tempContract.getStats(
            _idOfItem
        );
        require(tempWeaponStat.owner == msg.sender, "You dont own that weapon");

        if (_upgradeStat == 1) {
            require(
                tempWeaponStat.weaponCore >=
                    (tempStats.engramTier - 1) * 10000 &&
                    tempWeaponStat.weaponCore <= tempStats.engramTier * 10000,
                "Core not in correct Range"
            );
            tempStats.valueOfStatWhenUpgraded = tempWeaponStat.weaponCore;
        } else if (_upgradeStat == 2) {
            require(
                tempWeaponStat.weaponDamage >=
                    (tempStats.engramTier - 1) * 10000 &&
                    tempWeaponStat.weaponDamage <=
                    tempStats.engramTier * 10000 &&
                    tempWeaponStat.weaponDamage < 100000,
                "Damage not in correct Range"
            );
            tempStats.valueOfStatWhenUpgraded = tempWeaponStat.weaponDamage;
        }
        tempStats.engramState = EngramState.INITIALIZED;
        tempStats.initializationBlock = block.number;
        blockToCountToId[block.number][
            blockNumberCount[block.number]
        ] = _engramId;
        blockNumberCount[block.number] += 1;
        tempStats.idOfItemToUpgrade = _idOfItem;
        tempStats.statOfItemToUpgrade = _upgradeStat;
        tempStats.typeOfItemToUpgrade = 1;
        engramStats[_engramId] = tempStats;
        emit engramActivated(_engramId, block.number, tempStats.owner);
    }

    function activateDegen(
        uint256 _engramId,
        uint256 _upgradeStat,
        uint256 _idOfItem
    ) external {
        require(_upgradeStat >= 1 && _upgradeStat <= 2, "Select correct stat");
        require(
            !pendingDegenIds[_idOfItem],
            "Please wait for previous upgrade to resolve."
        );
        pendingDegenIds[_idOfItem] = true;
        itemStat memory tempStats = engramStats[_engramId];
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the engram can activate it"
        );
        require(
            tempStats.engramState == EngramState.OWNED,
            "Already Activated"
        );
        MythDegen tempContract = MythDegen(degenAddress);
        MythDegen.stats memory tempDegenStat = tempContract.getStats(_idOfItem);
        require(tempDegenStat.owner == msg.sender, "You dont own that Degen");

        if (_upgradeStat == 1) {
            require(
                tempDegenStat.coreScore >= (tempStats.engramTier - 1) * 10000 &&
                    tempDegenStat.coreScore <= tempStats.engramTier * 10000,
                "Core not in correct Range"
            );
            tempStats.valueOfStatWhenUpgraded = tempDegenStat.coreScore;
        } else if (_upgradeStat == 2) {
            require(
                tempDegenStat.damageCap >= (tempStats.engramTier - 1) * 10000 &&
                    tempDegenStat.damageCap <= tempStats.engramTier * 10000 &&
                    tempDegenStat.damageCap < 100000,
                "Damage not in correct Range"
            );
            tempStats.valueOfStatWhenUpgraded = tempDegenStat.damageCap;
        }
        tempStats.engramState = EngramState.INITIALIZED;
        tempStats.initializationBlock = block.number;
        blockToCountToId[block.number][
            blockNumberCount[block.number]
        ] = _engramId;
        blockNumberCount[block.number] += 1;
        tempStats.idOfItemToUpgrade = _idOfItem;
        tempStats.statOfItemToUpgrade = _upgradeStat;
        tempStats.typeOfItemToUpgrade = 4;
        engramStats[_engramId] = tempStats;
        emit engramActivated(_engramId, block.number, tempStats.owner);
    }

    function activateMod(uint256 _engramId, uint256 _idOfItem) external {
        require(
            !pendingModIds[_idOfItem],
            "Please wait for previous upgrade to resolve."
        );
        pendingModIds[_idOfItem] = true;
        itemStat memory tempStats = engramStats[_engramId];
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the engram can activate it"
        );
        require(
            tempStats.engramState == EngramState.OWNED,
            "Already Activated"
        );
        MythCityMods tempContract = MythCityMods(modAddress);
        MythCityMods.itemStat memory tempModStat = tempContract.getStats(
            _idOfItem
        );
        require(tempModStat.owner == msg.sender, "You dont own that Mod");

        require(
            tempModStat.modStat >= (tempStats.engramTier - 1) * 10000 &&
                tempModStat.modStat <= tempStats.engramTier * 10000,
            "Damage not in correct Range"
        );
        tempStats.engramState = EngramState.INITIALIZED;
        tempStats.valueOfStatWhenUpgraded = tempModStat.modStat;
        tempStats.initializationBlock = block.number;
        blockToCountToId[block.number][
            blockNumberCount[block.number]
        ] = _engramId;
        blockNumberCount[block.number] += 1;
        tempStats.idOfItemToUpgrade = _idOfItem;
        tempStats.statOfItemToUpgrade = 2;
        tempStats.typeOfItemToUpgrade = 2;
        engramStats[_engramId] = tempStats;
        emit engramActivated(_engramId, block.number, tempStats.owner);
    }

    function activateEquipment(uint256 _engramId, uint256 _idOfItem) external {
        require(
            !pendingEquipmentIds[_idOfItem],
            "Please wait for previous upgrade to resolve."
        );
        pendingEquipmentIds[_idOfItem] = true;
        itemStat memory tempStats = engramStats[_engramId];
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the engram can activate it"
        );
        require(
            tempStats.engramState == EngramState.OWNED,
            "Already Activated"
        );
        MythCityEquipment tempContract = MythCityEquipment(equipmentAddress);
        MythCityEquipment.itemStat memory tempEquipmentStat = tempContract
            .getStats(_idOfItem);
        require(
            tempEquipmentStat.owner == msg.sender,
            "You dont own that Equipment"
        );

        require(
            tempEquipmentStat.equipmentStat >=
                (tempStats.engramTier - 1) * 10000 &&
                tempEquipmentStat.equipmentStat <= tempStats.engramTier * 10000,
            "Core not in correct Range"
        );
        tempStats.engramState = EngramState.INITIALIZED;
        tempStats.valueOfStatWhenUpgraded = tempEquipmentStat.equipmentStat;
        tempStats.initializationBlock = block.number;
        blockToCountToId[block.number][
            blockNumberCount[block.number]
        ] = _engramId;
        blockNumberCount[block.number] += 1;
        tempStats.idOfItemToUpgrade = _idOfItem;
        tempStats.statOfItemToUpgrade = 1;
        tempStats.typeOfItemToUpgrade = 3;
        engramStats[_engramId] = tempStats;
        emit engramActivated(_engramId, block.number, tempStats.owner);
    }

    function resolveEngram(uint256 _blockNumber, bytes32 _resolutionSeed)
        external
    {
        require(
            resolverAddresses[msg.sender],
            "Only whitelisted addresses can resolve tokens"
        );
        require(
            resolvedBlocks[_blockNumber] == false,
            "Block Number Already Resolved"
        );
        require(block.number > _blockNumber, "Can only set previous blocks");
        uint256 resolveCountOfBlock = blockNumberCount[_blockNumber];
        require(resolveCountOfBlock > 0, "Nothing to resolve");
        uint256 counter = 0;
        resolvedBlocks[_blockNumber] = true;
        while (counter < resolveCountOfBlock) {
            uint256 tempId = blockToCountToId[_blockNumber][counter];
            itemStat memory currentEngram = engramStats[tempId];
            if (currentEngram.engramState != EngramState.INITIALIZED) {
                counter++;
                continue;
            }
            currentEngram.resolutionSeed = _resolutionSeed;
            currentEngram.engramState = EngramState.RESOLVED;
            currentEngram.numberRolled =
                uint256(keccak256(abi.encodePacked(_resolutionSeed, tempId))) %
                100000;
            engramStats[tempId] = currentEngram;
            counter++;
        }
        emit blockResolved(_blockNumber);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        itemStat memory tempStats = engramStats[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        Base64.concatenate(
                            "Engram #",
                            Base64.uint2str(tokenId)
                        ),
                        '",',
                        '"attributes": [{"trait_type": "Engram Id", "value": ',
                        Base64.uint2str(tokenId),
                        '},{"trait_type": "Engram Tier", "value": ',
                        Base64.uint2str(engramStats[tokenId].engramTier),
                        '},{"trait_type": "Engram State", "value": ',
                        Base64.uint2str(
                            uint256(engramStats[tokenId].engramState)
                        ),
                        "},",
                        getExtraMetaData(tokenId),
                        "]",
                        ',"image_data" : "',
                        tableAddressImageUrl[tempStats.engramTable],
                        '","external_url": "mythcity.app","description":"Unlock the power of the Multi Verse, change the stat of an item by a %."',
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
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

    function getExtraMetaData(uint256 _engramId)
        public
        view
        returns (string memory)
    {
        itemStat memory tempStats = engramStats[_engramId];
        string memory json = string(
            abi.encodePacked(
                '{"trait_type":"Engram Table", "value":"',
                toString(abi.encodePacked(tempStats.engramTable)),
                '"},{"trait_type":"Upgrade Item Id","display_type": "number","value":',
                Base64.uint2str(tempStats.idOfItemToUpgrade),
                '},{"trait_type":"Upgrade Item Type","display_type": "number", "value":',
                Base64.uint2str(tempStats.typeOfItemToUpgrade),
                '},{"trait_type":"Upgrade Stat Type","display_type": "number", "value":',
                Base64.uint2str(tempStats.statOfItemToUpgrade),
                "}",
                getExtraMetaData2(_engramId),
                ',{"trait_type":"Resolution Seed", "value":"',
                toString(abi.encodePacked(tempStats.resolutionSeed)),
                '"}'
            )
        );
        return json;
    }

    function getExtraMetaData2(uint256 _engramId)
        public
        view
        returns (string memory)
    {
        itemStat memory tempStats = engramStats[_engramId];
        string memory json = string(
            abi.encodePacked(
                ',{"trait_type":"Stat Before","display_type": "number", "value":',
                Base64.uint2str(tempStats.valueOfStatWhenUpgraded),
                '},{"trait_type":"Stat After","display_type": "number", "value":',
                Base64.uint2str(tempStats.statOfItemAfterUpgrade),
                '},{"trait_type":"Block Number Initialized","display_type": "number", "value":',
                Base64.uint2str(tempStats.initializationBlock),
                '},{"trait_type":"Number Rolled","display_type": "number", "value":',
                Base64.uint2str(tempStats.numberRolled),
                "}"
            )
        );
        return json;
    }

    function upgradeWeapon(uint256 _engramId) external returns (bool) {
        itemStat memory currentEngram = engramStats[_engramId];
        require(
            currentEngram.engramState == EngramState.RESOLVED,
            "Can only upgrade Engrams in the Resolved State"
        );
        require(
            currentEngram.typeOfItemToUpgrade == 1,
            "Only weapon type engrams can use this function."
        );
        engramStats[_engramId].engramState = EngramState.UPGRADED;
        currentEngram.engramState = EngramState.UPGRADED;
        pendingWeaponIds[currentEngram.idOfItemToUpgrade] = false;
        MythCityWeapons tempContract = MythCityWeapons(weaponAddress);
        MythCityWeapons.itemStat memory tempWeaponStats = tempContract.getStats(
            currentEngram.idOfItemToUpgrade
        );
        EngramTable tableContract = EngramTable(currentEngram.engramTable);
        EngramTable.prize memory tempPrize = tableContract.getWinningPrize(
            uint128(currentEngram.numberRolled)
        );
        uint256 newStatValue = 0;
        if (currentEngram.statOfItemToUpgrade == 1) {
            newStatValue = tempWeaponStats.weaponCore * 10**18;
            newStatValue = (newStatValue / 100000) * tempPrize.multiFactor;
            newStatValue = newStatValue / 10**18;
            require(
                tempContract.regradeWeaponStat(
                    currentEngram.idOfItemToUpgrade,
                    newStatValue,
                    0
                ),
                "Upgrade Failed"
            );
        } else {
            newStatValue = tempWeaponStats.weaponDamage * 10**18;
            newStatValue = (newStatValue / 100000) * tempPrize.multiFactor;
            newStatValue = newStatValue / 10**18;
            require(
                tempContract.regradeWeaponStat(
                    currentEngram.idOfItemToUpgrade,
                    0,
                    newStatValue
                ),
                "Upgrade Failed"
            );
        }
        currentEngram.statOfItemAfterUpgrade = newStatValue;
        engramStats[_engramId] = currentEngram;
        emit engramUpgraded(
            currentEngram.owner,
            _engramId,
            tempWeaponStats.degenIdEquipped,
            currentEngram.idOfItemToUpgrade,
            currentEngram.typeOfItemToUpgrade,
            currentEngram.valueOfStatWhenUpgraded,
            currentEngram.statOfItemAfterUpgrade
        );
        return true;
    }

    function upgradeDegen(uint256 _engramId) external returns (bool) {
        itemStat memory currentEngram = engramStats[_engramId];
        require(
            currentEngram.engramState == EngramState.RESOLVED,
            "Can only upgrade Engrams in the Resolved State"
        );
        require(
            currentEngram.typeOfItemToUpgrade == 4,
            "Only Degen type engrams can use this function."
        );
        engramStats[_engramId].engramState = EngramState.UPGRADED;
        currentEngram.engramState = EngramState.UPGRADED;
        pendingDegenIds[currentEngram.idOfItemToUpgrade] = false;
        MythDegen tempContract = MythDegen(degenAddress);
        MythDegen.stats memory tempDegenStats = tempContract.getStats(
            currentEngram.idOfItemToUpgrade
        );
        EngramTable tableContract = EngramTable(currentEngram.engramTable);
        EngramTable.prize memory tempPrize = tableContract.getWinningPrize(
            uint128(currentEngram.numberRolled)
        );
        uint256 newStatValue = 0;
        if (currentEngram.statOfItemToUpgrade == 1) {
            newStatValue = tempDegenStats.coreScore * 10**18;
            newStatValue = (newStatValue / 100000) * tempPrize.multiFactor;
            newStatValue = newStatValue / 10**18;
            require(
                tempContract.reGradeDegen(
                    currentEngram.idOfItemToUpgrade,
                    newStatValue,
                    0
                ),
                "Upgrade Failed"
            );
        } else {
            newStatValue = tempDegenStats.damageCap * 10**18;
            newStatValue = (newStatValue / 100000) * tempPrize.multiFactor;
            newStatValue = newStatValue / 10**18;
            require(
                tempContract.reGradeDegen(
                    currentEngram.idOfItemToUpgrade,
                    0,
                    newStatValue
                ),
                "Upgrade Failed"
            );
        }
        currentEngram.statOfItemAfterUpgrade = newStatValue;
        engramStats[_engramId] = currentEngram;
        emit engramUpgraded(
            currentEngram.owner,
            _engramId,
            currentEngram.idOfItemToUpgrade,
            currentEngram.idOfItemToUpgrade,
            currentEngram.typeOfItemToUpgrade,
            currentEngram.valueOfStatWhenUpgraded,
            currentEngram.statOfItemAfterUpgrade
        );
        return true;
    }

    function upgradeMod(uint256 _engramId) external returns (bool) {
        itemStat memory currentEngram = engramStats[_engramId];
        require(
            currentEngram.engramState == EngramState.RESOLVED,
            "Can only upgrade Engrams in the Resolved State"
        );
        require(
            currentEngram.typeOfItemToUpgrade == 2,
            "Only Mod type engrams can use this function."
        );
        engramStats[_engramId].engramState = EngramState.UPGRADED;
        currentEngram.engramState = EngramState.UPGRADED;
        pendingModIds[currentEngram.idOfItemToUpgrade] = false;
        MythCityMods tempContract = MythCityMods(modAddress);
        MythCityMods.itemStat memory tempModStats = tempContract.getStats(
            currentEngram.idOfItemToUpgrade
        );
        EngramTable tableContract = EngramTable(currentEngram.engramTable);
        EngramTable.prize memory tempPrize = tableContract.getWinningPrize(
            uint128(currentEngram.numberRolled)
        );
        uint256 newStatValue = 0;
        newStatValue = tempModStats.modStat * 10**18;
        newStatValue = (newStatValue / 100000) * tempPrize.multiFactor;
        newStatValue = newStatValue / 10**18;
        require(
            tempContract.regradeModStat(
                currentEngram.idOfItemToUpgrade,
                newStatValue
            ),
            "Upgrade Failed"
        );
        currentEngram.statOfItemAfterUpgrade = newStatValue;
        engramStats[_engramId] = currentEngram;
        emit engramUpgraded(
            currentEngram.owner,
            _engramId,
            tempModStats.degenIdEquipped,
            currentEngram.idOfItemToUpgrade,
            currentEngram.typeOfItemToUpgrade,
            currentEngram.valueOfStatWhenUpgraded,
            currentEngram.statOfItemAfterUpgrade
        );
        return true;
    }

    function upgradeEquipment(uint256 _engramId) external returns (bool) {
        itemStat memory currentEngram = engramStats[_engramId];
        require(
            currentEngram.engramState == EngramState.RESOLVED,
            "Can only upgrade Engrams in the Resolved State"
        );
        require(
            currentEngram.typeOfItemToUpgrade == 3,
            "Only Mod type engrams can use this function."
        );
        engramStats[_engramId].engramState = EngramState.UPGRADED;
        currentEngram.engramState = EngramState.UPGRADED;
        pendingEquipmentIds[currentEngram.idOfItemToUpgrade] = false;
        MythCityEquipment tempContract = MythCityEquipment(equipmentAddress);
        MythCityEquipment.itemStat memory tempEquipmentStats = tempContract
            .getStats(currentEngram.idOfItemToUpgrade);
        EngramTable tableContract = EngramTable(currentEngram.engramTable);

        EngramTable.prize memory tempPrize = tableContract.getWinningPrize(
            uint128(currentEngram.numberRolled)
        );
        uint256 newStatValue = 0;
        newStatValue = tempEquipmentStats.equipmentStat * 10**18;
        newStatValue = (newStatValue / 100000) * tempPrize.multiFactor;
        newStatValue = newStatValue / 10**18;
        require(
            tempContract.regradeEquipmentStat(
                currentEngram.idOfItemToUpgrade,
                newStatValue
            ),
            "Upgrade Failed"
        );
        currentEngram.statOfItemAfterUpgrade = newStatValue;
        engramStats[_engramId] = currentEngram;
        emit engramUpgraded(
            currentEngram.owner,
            _engramId,
            tempEquipmentStats.degenIdEquipped,
            currentEngram.idOfItemToUpgrade,
            currentEngram.typeOfItemToUpgrade,
            currentEngram.valueOfStatWhenUpgraded,
            currentEngram.statOfItemAfterUpgrade
        );
        return true;
    }
}