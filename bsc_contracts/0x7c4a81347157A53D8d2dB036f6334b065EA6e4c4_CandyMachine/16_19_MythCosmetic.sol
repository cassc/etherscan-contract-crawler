// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "ERC721.sol";
import "Degen.sol";

contract MythCosmetic is ERC721 {
    address public owner;
    uint256 public tokenCount;

    mapping(address => bool) public whitelistedAddresses;
    mapping(uint256 => itemStat) public cosmeticStats;
    mapping(uint256 => mapping(uint256 => string)) public cosmeticURL;
    mapping(uint256 => mapping(uint256 => string)) public cosmeticName;
    mapping(uint256 => mapping(uint256 => bool)) public cosmeticExists;
    mapping(uint256 => mapping(uint256 => uint256)) public degenToCosmetic;

    event whitelistAdded(address whitelistedAddress, bool isWhitelisted);
    event ownerChanged(address to, uint256 cosmeticId);
    event cosmeticMinted(
        address to,
        uint256 imageId,
        uint256 layerType,
        uint256 nameId
    );

    struct itemStat {
        address owner;
        uint256 imageId;
        uint256 layerType;
        uint256 nameId;
        uint256 degenIdEquipped;
    }
    event cosmeticAdded(
        uint256 layerType,
        uint256 layerId,
        string imageURL,
        string imageName
    );
    event cosmeticRemoved(uint256 layerType, uint256 layerId);
    event cosmeticEquipped(
        uint256 degenId,
        uint256 layerType,
        uint256 layerId,
        uint256 oldId,
        address owner,
        string imageName
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    modifier isWhitelisted() {
        require(
            whitelistedAddresses[msg.sender] || owner == msg.sender,
            "Not white listed"
        );
        _;
    }

    constructor(address _degenAddress)
        ERC721("Myth City Cosmetics", "MYTHCOS")
    {
        tokenCount = 1;
        owner = msg.sender;
        whitelistedAddresses[msg.sender] = true;
        whitelistedAddresses[_degenAddress] = true;
    }

    function alterWhitelist(address _address) external isWhitelisted {
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
        emit whitelistAdded(_address, whitelistedAddresses[_address]);
    }

    function overrideOwnerOfDegen(
        uint256 _degenId,
        address _from,
        address newOwner
    ) external isWhitelisted returns (bool) {
        for (uint256 i = 0; i < 11; i++) {
            uint256 tempCosmeticId = degenToCosmetic[_degenId][i];
            if (tempCosmeticId > 0) {
                cosmeticStats[tempCosmeticId].owner = newOwner;
                _transfer(_from, newOwner, tempCosmeticId);
            }
        }
        return true;
    }

    function getImageURL(uint256 _id) public view returns (string memory) {
        itemStat memory tempStats = cosmeticStats[_id];
        return cosmeticURL[tempStats.layerType][tempStats.imageId];
    }

    function getCosmeticName(uint256 _id) public view returns (string memory) {
        itemStat memory tempStats = cosmeticStats[_id];
        return cosmeticName[tempStats.layerType][tempStats.imageId];
    }

    function getUrl(uint256 _layer, uint256 _id)
        public
        view
        returns (string memory)
    {
        return cosmeticURL[_layer][_id];
    }

    function getName(uint256 _layer, uint256 _id)
        public
        view
        returns (string memory)
    {
        return cosmeticName[_layer][_id];
    }

    function getStats(uint256 _cosmeticId)
        public
        view
        returns (itemStat memory)
    {
        return cosmeticStats[_cosmeticId];
    }

    function idExists(uint256 _layerType, uint256 _itemId)
        public
        view
        returns (bool)
    {
        return cosmeticExists[_layerType][_itemId];
    }

    function equipCosmetic(uint256 _cosmeticId, uint256 _degenId)
        external
        isWhitelisted
        returns (bool)
    {
        require(
            cosmeticStats[_cosmeticId].degenIdEquipped == 0,
            "Cosmetic is already Equipped"
        );
        uint256 tempLayerType = cosmeticStats[_cosmeticId].layerType;
        cosmeticStats[_cosmeticId].degenIdEquipped = _degenId;
        cosmeticStats[degenToCosmetic[_degenId][tempLayerType]]
            .degenIdEquipped = 0;
        uint256 tempOldId = degenToCosmetic[_degenId][tempLayerType];
        degenToCosmetic[_degenId][tempLayerType] = _cosmeticId;
        emit cosmeticEquipped(
            _degenId,
            tempLayerType,
            _cosmeticId,
            tempOldId,
            cosmeticStats[_cosmeticId].owner,
            cosmeticName[tempLayerType][_cosmeticId]
        );
        return true;
    }

    function getIdOfCosmeticLayerAndDegen(uint256 _degenId, uint256 _layerId)
        public
        view
        returns (uint256)
    {
        return degenToCosmetic[_degenId][_layerId];
    }

    function unequipCosmetic(uint256 _degenId, uint256 _layerId)
        external
        isWhitelisted
        returns (bool)
    {
        delete cosmeticStats[degenToCosmetic[_degenId][_layerId]]
            .degenIdEquipped;
        uint256 tempOldId = degenToCosmetic[_degenId][_layerId];
        address ownerAddress = cosmeticStats[
            degenToCosmetic[_degenId][_layerId]
        ].owner;
        delete degenToCosmetic[_degenId][_layerId];
        emit cosmeticEquipped(
            _degenId,
            _layerId,
            0,
            tempOldId,
            ownerAddress,
            ""
        );
        return true;
    }

    function mint(
        address _to,
        uint256 _imageId,
        uint256 _layerType,
        uint256 _nameId
    ) external isWhitelisted returns (bool) {
        require(idExists(_layerType, _imageId), "This id does not exist");
        uint256 tempCount = tokenCount;
        emit cosmeticMinted(_to, _imageId, _layerType, _nameId);
        _mint(_to, tempCount);
        cosmeticStats[tempCount] = itemStat(
            _to,
            _imageId,
            _layerType,
            _nameId,
            0
        );
        tokenCount++;
        return true;
    }

    function removeCosmetic(uint256 _layerType, uint256 _id)
        external
        onlyOwner
    {
        delete cosmeticURL[_layerType][_id];
        delete cosmeticExists[_layerType][_id];
        delete cosmeticName[_layerType][_id];
        emit cosmeticRemoved(_layerType, _id);
    }

    function addCosmeticImageId(
        uint256 _layerType,
        uint256[] calldata _imageId,
        string[] calldata _urls,
        string[] calldata _imageNames
    ) external isWhitelisted {
        require(
            _imageId.length == _urls.length &&
                _urls.length == _imageNames.length,
            "Lists need to be same length"
        );
        for (uint256 i = 0; i < _urls.length; i++) {
            emit cosmeticAdded(
                _layerType,
                _imageId[i],
                _urls[i],
                _imageNames[i]
            );
            cosmeticURL[_layerType][_imageId[i]] = _urls[i];
            cosmeticExists[_layerType][_imageId[i]] = true;
            cosmeticName[_layerType][_imageId[i]] = _imageNames[i];
        }
    }

    function getAttributeData(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        itemStat memory tempStats = cosmeticStats[tokenId];
        string memory json = string(
            abi.encodePacked(
                '{"trait_type":"Cosmetic Id","display_type": "number", "value":',
                Base64.uint2str(tokenId),
                '},{"trait_type":"Layer Id","display_type": "number","value":',
                Base64.uint2str(tempStats.layerType),
                '},{"trait_type":"Image Id","display_type": "number", "value":',
                Base64.uint2str(tempStats.imageId),
                '},{"trait_type":"Equipped to Degen Id","display_type": "number", "value":',
                Base64.uint2str(tempStats.degenIdEquipped),
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
        itemStat memory tempStats = cosmeticStats[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        cosmeticName[tempStats.layerType][tempStats.imageId],
                        '",',
                        '"attributes": [',
                        getAttributeData(tokenId),
                        "]",
                        ',"image" : "',
                        cosmeticURL[tempStats.layerType][tempStats.imageId],
                        ' ","external_url": "mythcity.app","description":"Cosmetics used to override the looks of a Degenerate."',
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function transfer(uint256 _cosmeticId, address _to) external {
        require(
            cosmeticStats[_cosmeticId].owner == msg.sender,
            "Only the owner can transfer with this method"
        );
        require(
            cosmeticStats[_cosmeticId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _transfer(msg.sender, _to, _cosmeticId);
        cosmeticStats[_cosmeticId].owner = _to;
    }

    function transferFrom(
        address from,
        address _to,
        uint256 _cosmeticId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _cosmeticId),
            "ERC721: caller is not token owner or approved"
        );
        require(
            cosmeticStats[_cosmeticId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _transfer(from, _to, _cosmeticId);
        cosmeticStats[_cosmeticId].owner = _to;
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
            cosmeticStats[tokenId].degenIdEquipped == 0,
            "Cannot transfer while equipped"
        );
        _safeTransfer(from, to, tokenId, data);
        cosmeticStats[tokenId].owner = to;
    }

    function overrideOwner(
        uint256 _cosmeticId,
        address _from,
        address _newOwner
    ) external isWhitelisted returns (bool) {
        _transfer(_from, _newOwner, _cosmeticId);
        cosmeticStats[_cosmeticId].owner = _newOwner;
        return true;
    }
}