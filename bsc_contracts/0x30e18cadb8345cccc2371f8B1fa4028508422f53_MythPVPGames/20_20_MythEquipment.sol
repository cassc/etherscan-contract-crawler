// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ERC721.sol";
import "Degen.sol";

contract MythCityEquipment is ERC721 {
    address public owner;
    uint256 public tokenCount;
    mapping(address => bool) public whitelistedAddresses;
    mapping(uint256 => string) public equipmentURL;
    mapping(uint256 => string) public equipmentName;
    mapping(uint256 => bool) public equipmentExists;
    mapping(uint256 => uint256) public degenToEquipment;

    mapping(uint256 => itemStat) public equipmentStats;
    event whitelistAdded(address whitelistedAddress, bool isWhitelisted);
    event equipmentAdded(uint256 id, string url, string nameOfToken);
    event equipmentEquipped(
        uint256 equipmentId,
        uint256 degenId,
        uint256 oldId,
        address owner
    );
    event equipmentRegrade(uint256 equipmentId, uint256 equipmentStat);
    event equipmentMinted(
        address to,
        uint256 imageId,
        uint256 itemStat,
        uint256 routeType,
        bool isWings,
        string equipmentName
    );
    event ownerChanged(address to, uint256 equipmentId);
    struct itemStat {
        bool isWings;
        address owner;
        uint256 imageId;
        uint256 equipmentStat;
        uint256 degenIdEquipped;
        uint256 equipmentRouteBoost;
        uint256 nameOfEquipmentId;
    }
    modifier isWhitelisted() {
        require(
            whitelistedAddresses[msg.sender] || msg.sender == owner,
            "Not white listed"
        );
        _;
    }

    constructor(
        address _degenAddress
    ) ERC721("Myth City Equipment", "MYTHEQP") {
        tokenCount = 1;
        owner = msg.sender;
        whitelistedAddresses[msg.sender] = true;
        whitelistedAddresses[_degenAddress] = true;
    }

    function getStats(uint256 _id) public view returns (itemStat memory) {
        return equipmentStats[_id];
    }

    function getDegenData(
        uint256 _equipmentId
    ) public view returns (string memory) {
        itemStat memory tempStats = equipmentStats[_equipmentId];
        string memory json = string(
            abi.encodePacked(
                '{"trait_type":"Equipment Id","display_type": "number", "value":',
                uint2str(_equipmentId),
                '},{"trait_type":"Equipment Core","value":',
                uint2str(tempStats.equipmentStat),
                '},{"trait_type":"Equipment Route","display_type": "number", "value":',
                uint2str(tempStats.equipmentRouteBoost),
                '},{"trait_type":"Equipment Image Url","value":"',
                getImageFromId(_equipmentId),
                '"}'
            )
        );
        return json;
    }

    function getEquipmentData(
        uint256 _equipmentId
    ) public view returns (string memory) {
        itemStat memory tempStats = equipmentStats[_equipmentId];
        string memory json = string(
            abi.encodePacked(
                '{"trait_type":"Equipment Id","display_type": "number", "value":',
                uint2str(_equipmentId),
                '},{"trait_type":"Equipment Core","value":',
                uint2str(tempStats.equipmentStat),
                '},{"trait_type":"Equipment Route","display_type": "number", "value":',
                uint2str(tempStats.equipmentRouteBoost),
                '},{"trait_type":"Degen Equipped To","display_type": "number", "value":',
                uint2str(tempStats.degenIdEquipped),
                "}"
            )
        );

        return json;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        itemStat memory tempStats = equipmentStats[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        equipmentName[tempStats.nameOfEquipmentId],
                        '",',
                        '"attributes": [',
                        getEquipmentData(tokenId),
                        "]",
                        ',"image_data" : "',
                        getImageFromId(tokenId),
                        ' ","external_url": "mythcity.app", "description":"Equipment Used by Degenerates to help them on their missions."',
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
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

    function getImageFromId(uint256 _id) public view returns (string memory) {
        return equipmentURL[equipmentStats[_id].imageId];
    }

    function getImageURL(
        uint256 _equipmentId
    ) public view returns (string memory) {
        return equipmentURL[equipmentStats[_equipmentId].imageId];
    }

    function equipEquipment(
        uint256 _equipmentId,
        uint256 _degenId
    ) external isWhitelisted returns (bool) {
        require(
            equipmentStats[_equipmentId].degenIdEquipped == 0,
            "Equipment is already Equipped"
        );
        equipmentStats[_equipmentId].degenIdEquipped = _degenId;
        uint256 oldId = degenToEquipment[_degenId];
        equipmentStats[degenToEquipment[_degenId]].degenIdEquipped = 0;
        degenToEquipment[_degenId] = _equipmentId;
        emit equipmentEquipped(
            _equipmentId,
            _degenId,
            oldId,
            equipmentStats[_equipmentId].owner
        );
        return true;
    }

    function unequipEquipment(
        uint256 _degenId
    ) external isWhitelisted returns (bool) {
        delete equipmentStats[degenToEquipment[_degenId]].degenIdEquipped;
        uint256 oldId = degenToEquipment[_degenId];
        address tempOwner = equipmentStats[degenToEquipment[_degenId]].owner;
        delete degenToEquipment[_degenId];
        emit equipmentEquipped(0, _degenId, oldId, tempOwner);
        return true;
    }

    function transfer(uint256 _equipmentId, address _to) external {
        require(
            equipmentStats[_equipmentId].owner == msg.sender,
            "Only the owner can transfer with this method"
        );
        require(
            equipmentStats[_equipmentId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _transfer(msg.sender, _to, _equipmentId);
        equipmentStats[_equipmentId].owner = _to;
    }

    function transferFrom(
        address from,
        address _to,
        uint256 _equipmentId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _equipmentId),
            "ERC721: caller is not token owner or approved"
        );
        require(
            equipmentStats[_equipmentId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _transfer(from, _to, _equipmentId);
        equipmentStats[_equipmentId].owner = _to;
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
            equipmentStats[tokenId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _safeTransfer(from, to, tokenId, data);
        equipmentStats[tokenId].owner = to;
    }

    function overrideOwner(
        uint256 _equipmentId,
        address _from,
        address _newOwner
    ) external isWhitelisted returns (bool) {
        _transfer(_from, _newOwner, _equipmentId);
        equipmentStats[_equipmentId].owner = _newOwner;
        return true;
    }

    function upgradeEquipmentStat(
        uint256 _equipmentId,
        uint256 _statUpgrade
    ) external isWhitelisted {
        equipmentStats[_equipmentId].equipmentStat += _statUpgrade;
        emit equipmentRegrade(
            _equipmentId,
            equipmentStats[_equipmentId].equipmentStat
        );
    }

    function regradeEquipmentStat(
        uint256 _equipmentId,
        uint256 _statRegrade
    ) external isWhitelisted returns (bool) {
        equipmentStats[_equipmentId].equipmentStat = _statRegrade;
        emit equipmentRegrade(
            _equipmentId,
            equipmentStats[_equipmentId].equipmentStat
        );
        return true;
    }

    function mint(
        bool _isWings,
        address _to,
        uint256 _imageId,
        uint256 _equipmentStat,
        uint256 _route,
        uint256 _nameId
    ) external isWhitelisted returns (bool) {
        _mint(_to, tokenCount);
        emit equipmentMinted(
            _to,
            _imageId,
            _equipmentStat,
            _route,
            _isWings,
            equipmentName[_nameId]
        );
        equipmentStats[tokenCount] = itemStat(
            _isWings,
            _to,
            _imageId,
            _equipmentStat,
            0,
            _route,
            _nameId
        );
        tokenCount++;
        return true;
    }

    function removeEquipment(uint256 _id) external isWhitelisted {
        delete equipmentExists[_id];
        delete equipmentURL[_id];
        delete equipmentName[_id];
    }

    function changeEquipment(
        string[10] calldata _url,
        uint256[10] calldata _id,
        string[10] calldata _names
    ) external isWhitelisted {
        for (uint256 i = 0; i < 10; i++) {
            if (_id[i] > 0) {
                emit equipmentAdded(_id[i], _url[i], _names[i]);
                equipmentExists[_id[i]] = true;
                equipmentURL[_id[i]] = _url[i];
                equipmentName[_id[i]] = _names[i];
            }
        }
    }

    function alterWhitelist(address _address) external isWhitelisted {
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
        emit whitelistAdded(_address, whitelistedAddresses[_address]);
    }
}