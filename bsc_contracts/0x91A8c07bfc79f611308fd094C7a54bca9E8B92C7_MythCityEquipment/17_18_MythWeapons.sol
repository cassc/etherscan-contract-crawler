// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ERC721.sol";
import "MythWeaponSkins.sol";
import "Degen.sol";

contract MythCityWeapons is ERC721 {
    //Myth Weapons will have a image id, core stat and damage stat
    address public owner;
    uint256 public tokenCount;
    mapping(address => bool) public whitelistedAddresses;
    mapping(uint256 => string) public weaponURL;
    mapping(uint256 => string) public weaponName;
    mapping(uint256 => bool) public weaponExists;
    mapping(uint256 => uint256) public degenToWeapon;

    mapping(uint256 => itemStat) public weaponStats;
    mapping(uint256 => uint256) public weaponSkins;
    address public weaponSkinAddress;

    event weaponAdded(uint256 id, string url, string nameOfToken);
    event skinEquipped(address owner, uint256 oldID, uint256 newId);
    event weaponEquipped(
        uint256 weaponId,
        uint256 degenId,
        uint256 oldId,
        address owner
    );
    event weaponRegrade(
        uint256 weaponId,
        uint256 weaponCore,
        uint256 weaponDamage
    );
    event weaponMinted(
        address to,
        uint256 imageId,
        uint256 weaponCore,
        uint256 weaponDamage,
        uint256 weaponType,
        string weaponName
    );
    event ownerChanged(address to, uint256 weaponId);
    event whitelistAdded(address whitelistedAddress, bool isWhitelisted);

    struct itemStat {
        address owner;
        uint256 imageId;
        uint256 weaponCore;
        uint256 weaponDamage;
        uint256 degenIdEquipped;
        uint256 weaponType;
        uint256 nameOfWeaponId;
    }
    modifier isWhitelisted() {
        require(
            whitelistedAddresses[msg.sender] || msg.sender == owner,
            "Not white listed"
        );
        _;
    }

    constructor(address _degenAddress) ERC721("Myth City Weapons", "MYTHWEP") {
        tokenCount = 1;
        owner = msg.sender;
        whitelistedAddresses[msg.sender] = true;
        whitelistedAddresses[_degenAddress] = true;
    }

    function getStats(uint256 _weaponId) public view returns (itemStat memory) {
        return weaponStats[_weaponId];
    }

    function setSkinsAddress(address _address) external isWhitelisted {
        weaponSkinAddress = _address;
    }

    function getDegenData(uint256 _weaponId)
        public
        view
        returns (string memory)
    {
        itemStat memory tempStats = weaponStats[_weaponId];
        string memory json = string(
            abi.encodePacked(
                '{"trait_type":"Weapon Id","display_type": "number", "value":',
                uint2str(_weaponId),
                '},{"trait_type":"Weapon Core","value":',
                uint2str(tempStats.weaponCore),
                '},{"trait_type":"Weapon Damage","value":',
                uint2str(tempStats.weaponDamage),
                '},{"trait_type":"Weapon Type","display_type": "number", "value":',
                uint2str(tempStats.weaponType),
                '},{"trait_type":"Weapon Image Url","value":"',
                getImageFromId(_weaponId),
                '"}'
            )
        );

        return json;
    }

    function getWeaponData(uint256 _weaponId)
        public
        view
        returns (string memory)
    {
        itemStat memory tempStats = weaponStats[_weaponId];
        string memory json = string(
            abi.encodePacked(
                '{"trait_type":"Weapon Id","display_type": "number", "value":',
                uint2str(_weaponId),
                '},{"trait_type":"Weapon Core","value":',
                uint2str(tempStats.weaponCore),
                '},{"trait_type":"Weapon Damage","value":',
                uint2str(tempStats.weaponDamage),
                '},{"trait_type":"Weapon Type","display_type": "number", "value":',
                uint2str(tempStats.weaponType),
                '},{"trait_type":"Degen Equipped To","display_type": "number", "value":',
                uint2str(tempStats.degenIdEquipped),
                '},{"trait_type":"Weapon Skin Equipped","display_type": "number", "value":',
                uint2str(weaponSkins[_weaponId]),
                "}"
            )
        );

        return json;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        itemStat memory tempStats = weaponStats[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        weaponName[tempStats.nameOfWeaponId],
                        '",',
                        '"attributes": [',
                        getWeaponData(tokenId),
                        "]",
                        ',"image_data" : "',
                        getImageFromId(tokenId),
                        ' ","external_url": "mythcity.app","description":"Weapons Used by Degenerates to solve their problems."',
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getImageFromId(uint256 _id) public view returns (string memory) {
        if (weaponSkins[_id] > 0) {
            MythCityWeaponSkins tempSkins = MythCityWeaponSkins(
                weaponSkinAddress
            );
            return (tempSkins.getImageURL(weaponSkins[_id]));
        } else {
            return weaponURL[weaponStats[_id].imageId];
        }
    }

    function alterWhitelist(address _address) external isWhitelisted {
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
        emit whitelistAdded(_address, whitelistedAddresses[_address]);
    }

    function transfer(uint256 _weaponId, address _to) external {
        require(
            weaponStats[_weaponId].owner == msg.sender,
            "Only the owner can transfer with this method"
        );
        require(
            weaponStats[_weaponId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        uint256 tempSkins = weaponSkins[_weaponId];
        if (tempSkins > 0) {
            MythCityWeaponSkins tempSkinContract = MythCityWeaponSkins(
                weaponSkinAddress
            );
            require(
                tempSkinContract.overrideOwner(tempSkins, msg.sender, _to),
                "failed to transfer weapon skin"
            );
        }
        _transfer(msg.sender, _to, _weaponId);
        weaponStats[_weaponId].owner = _to;
        emit ownerChanged(_to, _weaponId);
    }

    function equipSkin(uint256 _weaponId, uint256 _skinId) external {
        require(
            weaponStats[_weaponId].owner == msg.sender,
            "Only the owner of the Weapon can use it"
        );

        MythCityWeaponSkins tempSkins = MythCityWeaponSkins(weaponSkinAddress);
        MythCityWeaponSkins.itemStat memory tempStats = tempSkins.getStats(
            _skinId
        );
        require(
            tempStats.owner == msg.sender &&
                tempStats.weaponType == weaponStats[_weaponId].weaponType,
            "Only the owner of the skin can use it or the weapon is not the same type"
        );
        bool isEquipped = tempSkins.equipSkin(_weaponId, _skinId);
        require(isEquipped, "Skin was not equipped");
        emit skinEquipped(msg.sender, weaponSkins[_weaponId], _skinId);
        weaponSkins[_weaponId] = _skinId;
    }

    function unequipSkin(uint256 _weaponId) external {
        require(
            weaponStats[_weaponId].owner == msg.sender,
            "Only the owner of the Weapon can use it"
        );
        require(weaponSkins[_weaponId] > 0, "No Skin equipped");
        MythCityWeaponSkins tempSkins = MythCityWeaponSkins(weaponSkinAddress);
        bool isEquipped = tempSkins.unequipSkin(_weaponId);
        require(isEquipped, "Skin was not un equipped");
        emit skinEquipped(msg.sender, weaponSkins[_weaponId], 0);
        delete weaponSkins[_weaponId];
    }

    function equipWeapon(uint256 _weaponId, uint256 _degenId)
        external
        isWhitelisted
        returns (bool)
    {
        require(
            weaponStats[_weaponId].degenIdEquipped == 0,
            "Weapon is already Equipped"
        );
        weaponStats[_weaponId].degenIdEquipped = _degenId;
        uint256 tempOldId = degenToWeapon[_degenId];
        weaponStats[degenToWeapon[_degenId]].degenIdEquipped = 0;
        degenToWeapon[_degenId] = _weaponId;
        emit weaponEquipped(
            _weaponId,
            _degenId,
            tempOldId,
            weaponStats[degenToWeapon[_degenId]].owner
        );
        return true;
    }

    function unequipWeapon(uint256 _degenId)
        external
        isWhitelisted
        returns (bool)
    {
        delete weaponStats[degenToWeapon[_degenId]].degenIdEquipped;
        uint256 tempOldId = degenToWeapon[_degenId];
        delete degenToWeapon[_degenId];
        emit weaponEquipped(
            0,
            _degenId,
            tempOldId,
            weaponStats[degenToWeapon[_degenId]].owner
        );
        return true;
    }

    function forceTransferEquips(
        uint256 _weaponId,
        address _from,
        address _to
    ) internal returns (bool) {
        uint256 tempSkins = weaponSkins[_weaponId];
        if (tempSkins > 0) {
            MythCityWeaponSkins tempSkinContract = MythCityWeaponSkins(
                weaponSkinAddress
            );
            require(
                tempSkinContract.overrideOwner(tempSkins, _from, _to),
                "failed to transfer weapon skin"
            );
        }
        return true;
    }

    function transferFrom(
        address from,
        address _to,
        uint256 _weaponId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _weaponId),
            "ERC721: caller is not token owner or approved"
        );
        require(
            weaponStats[_weaponId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _transfer(from, _to, _weaponId);
        require(
            forceTransferEquips(_weaponId, from, _to),
            "Failed to transfer Skins"
        );
        weaponStats[_weaponId].owner = _to;
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
            weaponStats[tokenId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _safeTransfer(from, to, tokenId, data);
        require(
            forceTransferEquips(tokenId, from, to),
            "Failed to transfer Skins"
        );
        weaponStats[tokenId].owner = to;
    }

    function overrideOwner(
        uint256 _weaponId,
        address _from,
        address _newOwner
    ) external isWhitelisted returns (bool) {
        uint256 tempSkins = weaponSkins[_weaponId];
        if (tempSkins > 0) {
            MythCityWeaponSkins tempSkinContract = MythCityWeaponSkins(
                weaponSkinAddress
            );
            require(
                tempSkinContract.overrideOwner(tempSkins, _from, _newOwner),
                "failed to transfer weapon skin"
            );
        }
        weaponStats[_weaponId].owner = _newOwner;
        _transfer(_from, _newOwner, _weaponId);
        return true;
    }

    function upgradeWeaponStat(
        uint256 _weaponId,
        uint256 _weaponCore,
        uint256 _weaponDamage
    ) external isWhitelisted {
        weaponStats[_weaponId].weaponCore += _weaponCore;
        weaponStats[_weaponId].weaponDamage += _weaponDamage;
        emit weaponRegrade(
            _weaponId,
            weaponStats[_weaponId].weaponCore,
            weaponStats[_weaponId].weaponDamage
        );
    }

    function regradeWeaponStat(
        uint256 _weaponId,
        uint256 _weaponCore,
        uint256 _weaponDamage
    ) external isWhitelisted returns (bool) {
        if (_weaponCore > 0) {
            weaponStats[_weaponId].weaponCore = _weaponCore;
        }
        if (_weaponDamage > 0) {
            weaponStats[_weaponId].weaponDamage = _weaponDamage;
        }
        emit weaponRegrade(
            _weaponId,
            weaponStats[_weaponId].weaponCore,
            weaponStats[_weaponId].weaponDamage
        );
        return true;
    }

    function mint(
        address _to,
        uint256 _imageId,
        uint256 _weaponCore,
        uint256 _weaponDamage,
        uint256 _weaponType,
        uint256 _nameId
    ) external isWhitelisted returns (bool) {
        _mint(_to, tokenCount);
        emit weaponMinted(
            _to,
            _imageId,
            _weaponCore,
            _weaponDamage,
            _weaponType,
            weaponName[_nameId]
        );
        weaponStats[tokenCount] = itemStat(
            _to,
            _imageId,
            _weaponCore,
            _weaponDamage,
            0,
            _weaponType,
            _nameId
        );
        tokenCount++;
        return true;
    }

    function removeWeapon(uint256 _id) external isWhitelisted {
        delete weaponExists[_id];
        delete weaponURL[_id];
        delete weaponName[_id];
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

    function changeWeapon(
        string[10] calldata _url,
        uint256[10] calldata _id,
        string[10] calldata _names
    ) external isWhitelisted {
        for (uint256 i = 0; i < 10; i++) {
            if (_id[i] > 0) {
                emit weaponAdded(_id[i], _url[i], _names[i]);
                weaponExists[_id[i]] = true;
                weaponURL[_id[i]] = _url[i];
                weaponName[_id[i]] = _names[i];
            }
        }
    }
}