// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ERC721.sol";
import "Degen.sol";

contract MythCityMods is ERC721 {
    //Myth Mods will have a image id, item stat
    address public owner;
    uint256 public tokenCount;
    mapping(address => bool) public whitelistedAddresses;
    mapping(uint256 => string) public modURL;
    mapping(uint256 => string) public modName;
    mapping(uint256 => bool) public modExists;
    mapping(uint256 => uint256) public degenToMod;

    mapping(uint256 => itemStat) public modStats;

    event modAdded(uint256 id, string url, string nameOfToken);
    event modEquipped(
        uint256 modId,
        uint256 degenId,
        uint256 oldId,
        address owner
    );
    event modRegrade(uint256 modId, uint256 modStat);
    event modMinted(
        address to,
        uint256 imageId,
        uint256 itemStat,
        string modName
    );
    event ownerChanged(address to, uint256 modId);
    event whitelistAdded(address whitelistedAddress, bool isWhitelisted);
    struct itemStat {
        address owner;
        uint256 imageId;
        uint256 modStat;
        uint256 degenIdEquipped;
        uint256 nameOfModId;
    }
    modifier isWhitelisted() {
        require(
            whitelistedAddresses[msg.sender] || msg.sender == owner,
            "Not white listed"
        );
        _;
    }

    constructor(address _degenAddress) ERC721("Myth City Mod", "MYTHMOD") {
        tokenCount = 1;
        owner = msg.sender;
        whitelistedAddresses[msg.sender] = true;
        whitelistedAddresses[_degenAddress] = true;
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

    function getDegenData(uint256 _modId) public view returns (string memory) {
        itemStat memory tempStats = modStats[_modId];
        string memory json = string(
            abi.encodePacked(
                '{"trait_type":"Mod Id","display_type": "number", "value":',
                uint2str(_modId),
                '},{"trait_type":"Mod Damage","value":',
                uint2str(tempStats.modStat),
                '},{"trait_type":"Mod Image Url","value":"',
                getImageFromId(_modId),
                '"}'
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
        itemStat memory tempStats = modStats[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        modName[tempStats.nameOfModId],
                        '",',
                        '"attributes": [{"trait_type": "Mod Id","display_type": "number",  "value":  ',
                        Base64.uint2str(tokenId),
                        '},{"trait_type": "Degen Id equipped to","display_type": "number",  "value": ',
                        Base64.uint2str(tempStats.degenIdEquipped),
                        '},{"trait_type": "Mod Damage", "value": ',
                        Base64.uint2str(tempStats.modStat),
                        "}",
                        "]",
                        ',"image_data" : "',
                        modURL[tempStats.imageId],
                        '","external_url": "mythcity.app","description":"Mods Used by Degenerates to boost their damage output."',
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getStats(uint256 _modId) public view returns (itemStat memory) {
        return modStats[_modId];
    }

    function getImageFromId(uint256 _id) public view returns (string memory) {
        return modURL[modStats[_id].imageId];
    }

    function alterWhitelist(address _address) external isWhitelisted {
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
        emit whitelistAdded(_address, whitelistedAddresses[_address]);
    }

    function transfer(uint256 _modId, address _to) external {
        require(
            modStats[_modId].owner == msg.sender,
            "Only the owner can transfer with this method"
        );
        require(
            modStats[_modId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _transfer(msg.sender, _to, _modId);
        modStats[_modId].owner = _to;
    }

    function transferFrom(
        address from,
        address _to,
        uint256 _modId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _modId),
            "ERC721: caller is not token owner or approved"
        );
        require(
            modStats[_modId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _transfer(from, _to, _modId);
        modStats[_modId].owner = _to;
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
            modStats[tokenId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _safeTransfer(from, to, tokenId, data);
        modStats[tokenId].owner = to;
    }

    function equipMod(uint256 _modId, uint256 _degenId)
        external
        isWhitelisted
        returns (bool)
    {
        require(
            modStats[_modId].degenIdEquipped == 0,
            "Mod is already Equipped"
        );
        modStats[_modId].degenIdEquipped = _degenId;
        uint256 tempOldId = degenToMod[_degenId];
        modStats[degenToMod[_degenId]].degenIdEquipped = 0;
        degenToMod[_degenId] = _modId;
        emit modEquipped(_modId, _degenId, tempOldId, modStats[_modId].owner);
        return true;
    }

    function unequipMod(uint256 _degenId)
        external
        isWhitelisted
        returns (bool)
    {
        delete modStats[degenToMod[_degenId]].degenIdEquipped;
        uint256 tempOldId = degenToMod[_degenId];
        delete degenToMod[_degenId];
        emit modEquipped(
            0,
            _degenId,
            tempOldId,
            modStats[degenToMod[_degenId]].owner
        );
        return true;
    }

    function overrideOwner(
        uint256 _modId,
        address _from,
        address _newOwner
    ) external isWhitelisted returns (bool) {
        _transfer(_from, _newOwner, _modId);
        modStats[_modId].owner = _newOwner;
        return true;
    }

    function upgradeModStat(uint256 _modId, uint256 _statUpgrade)
        external
        isWhitelisted
    {
        modStats[_modId].modStat += _statUpgrade;
        emit modRegrade(_modId, modStats[_modId].modStat);
    }

    function regradeModStat(uint256 _modId, uint256 _statRegrade)
        external
        isWhitelisted
        returns (bool)
    {
        modStats[_modId].modStat = _statRegrade;
        emit modRegrade(_modId, modStats[_modId].modStat);
        return true;
    }

    function mint(
        address _to,
        uint256 _imageId,
        uint256 _modStat,
        uint256 _modName
    ) external isWhitelisted returns (bool) {
        _mint(_to, tokenCount);
        emit modMinted(_to, _imageId, _modStat, modName[_modName]);
        modStats[tokenCount] = itemStat(_to, _imageId, _modStat, 0, _modName);
        tokenCount++;
        return true;
    }

    function removeMod(uint256 _id) external isWhitelisted {
        delete modExists[_id];
        delete modURL[_id];
        delete modName[_id];
    }

    function changeMod(
        string[10] calldata _url,
        uint256[10] calldata _id,
        string[10] calldata _names
    ) external isWhitelisted {
        for (uint256 i = 0; i < 10; i++) {
            if (_id[i] > 0) {
                emit modAdded(_id[i], _url[i], _names[i]);
                modExists[_id[i]] = true;
                modURL[_id[i]] = _url[i];
                modName[_id[i]] = _names[i];
            }
        }
    }
}