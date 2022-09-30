// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ERC721.sol";
import "Degen.sol";

contract MythCityWeaponSkins is ERC721 {
    address public owner;
    uint256 public tokenCount;
    mapping(address => bool) public whitelistedAddresses;
    mapping(uint256 => string) public skinURL;
    mapping(uint256 => bool) public skinExists;
    mapping(uint256 => string) public skinName;
    mapping(uint256 => uint256) public weaponToSkin;
    mapping(uint256 => itemStat) public skinStats;
    struct itemStat {
        address owner;
        uint256 imageId;
        uint256 weaponIdEquipped;
        uint256 weaponType;
        uint256 nameOfSkinId;
    }
    event whitelistAdded(address whitelistedAddress, bool isWhitelisted);
    event skinMinted(
        address to,
        uint256 imageId,
        uint256 weaponType,
        string skinName
    );
    event ownerChanged(address to, uint256 weaponId);
    event skinEquipped(uint256 weaponId, uint256 skinId);
    event skinURLAdded(uint256 skinId, string imageURL, string nameOfToken);
    modifier isWhitelisted() {
        require(
            whitelistedAddresses[msg.sender] || msg.sender == owner,
            "Not white listed"
        );
        _;
    }

    constructor(address _weaponAddress)
        ERC721("Myth City Weapon Skins", "WEPSKIN")
    {
        tokenCount = 1;
        owner = msg.sender;
        whitelistedAddresses[msg.sender] = true;
        whitelistedAddresses[_weaponAddress] = true;
    }

    function alterWhitelist(address _address) external isWhitelisted {
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
        emit whitelistAdded(_address, whitelistedAddresses[_address]);
    }

    function changeSkinURLs(
        string[10] calldata _url,
        uint256[10] calldata _id,
        string[10] calldata _names
    ) external isWhitelisted {
        for (uint256 i = 0; i < 10; i++) {
            if (_id[i] > 0) {
                emit skinURLAdded(_id[i], _url[i], _names[i]);
                skinExists[i] = true;
                skinURL[i] = _url[i];
                skinName[i] = _names[i];
            }
        }
    }

    function getStats(uint256 _skinId) public view returns (itemStat memory) {
        return skinStats[_skinId];
    }

    function overrideOwner(
        uint256 _skinId,
        address _from,
        address _newOwner
    ) external isWhitelisted returns (bool) {
        _transfer(_from, _newOwner, _skinId);
        skinStats[_skinId].owner = _newOwner;
        return true;
    }

    function transfer(uint256 _skinId, address _to) external {
        require(
            skinStats[_skinId].owner == msg.sender,
            "Only the owner can transfer with this method"
        );
        require(
            skinStats[_skinId].weaponIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        skinStats[_skinId].owner = _to;
        _transfer(msg.sender, _to, _skinId);
    }

    function transferFrom(
        address from,
        address _to,
        uint256 _skinId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _skinId),
            "ERC721: caller is not token owner or approved"
        );
        require(
            skinStats[_skinId].weaponIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _transfer(from, _to, _skinId);
        skinStats[_skinId].owner = _to;
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
            skinStats[tokenId].weaponIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _safeTransfer(from, to, tokenId, data);
        skinStats[tokenId].owner = to;
    }

    function mint(
        address _to,
        uint256 _imageId,
        uint256 _weaponType,
        uint256 _skinName
    ) external isWhitelisted returns (bool) {
        _mint(_to, tokenCount);
        emit skinMinted(_to, _imageId, _weaponType, skinName[_skinName]);
        skinStats[tokenCount] = itemStat(
            _to,
            _imageId,
            0,
            _weaponType,
            _skinName
        );
        tokenCount++;
        return true;
    }

    function equipSkin(uint256 _weaponId, uint256 _skinId)
        external
        isWhitelisted
        returns (bool)
    {
        require(
            skinStats[_skinId].weaponIdEquipped == 0,
            "Skin is already Equipped"
        );
        skinStats[_skinId].weaponIdEquipped = _weaponId;
        skinStats[weaponToSkin[_weaponId]].weaponIdEquipped = 0;
        weaponToSkin[_weaponId] = _skinId;
        emit skinEquipped(_weaponId, _skinId);
        return true;
    }

    function unequipSkin(uint256 _weaponId)
        external
        isWhitelisted
        returns (bool)
    {
        delete skinStats[weaponToSkin[_weaponId]].weaponIdEquipped;
        delete weaponToSkin[_weaponId];
        emit skinEquipped(_weaponId, 0);
        return true;
    }

    function getImageURL(uint256 _id) public view returns (string memory) {
        return skinURL[_id];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        itemStat memory tempStats = skinStats[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        skinName[tempStats.nameOfSkinId],
                        '",',
                        '"attributes": [{"trait_type": "Skin id","display_type": "number",  "value": ',
                        Base64.uint2str(tokenId),
                        '},{"trait_type": "Weapon Id equipped to","display_type": "number",  "value": ',
                        Base64.uint2str(tempStats.weaponIdEquipped),
                        '},{"trait_type": "Weapon Type","display_type": "number",  "value": ',
                        Base64.uint2str(tempStats.weaponType),
                        "}",
                        "]",
                        ',"image" : "',
                        skinURL[tempStats.imageId],
                        ' ","external_url": "mythcity.app","description":"Weapon Skins that make you look even COOLER."',
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}