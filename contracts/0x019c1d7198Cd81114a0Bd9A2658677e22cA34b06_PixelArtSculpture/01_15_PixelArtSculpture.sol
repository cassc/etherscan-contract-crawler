// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct Piece {
    string title;
    string colorOf; 
    string styleOf;
    string typeOf;
}

contract PixelArtSculpture is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 immutable public maxSupply = 1000;
    bool public traitsLocked;
    bool[1001] public metadataLocked; 
    string[] private colorList = ["monotone", "color"];
    string[] private styleList = [
        "Prehistoric_periods", "Ancient_Near_East", "Encient_Egypt", "Ancient_Greece", "Classical", 
        "Hellenistic", "Roman_sculpture", "Early_Medieval_and_Byzantine", "Romanesque", "Gothic", 
        "Renaissance", "Mannerist", "Baroque_and_Rococo", "Neo-Classical", "Greco-Buddhist_sculpture_and_Asia", 
        "China", "Japan", "Indian_subcontinent", "South-East_Asia", "Islam", 
        "Africa", "Ethiopia_and_Eritrea", "Sudan", "Pre-Columbian", "North_America", 
        "19th-early_20th_century", "Modernism", "Contemporary"
    ];
    string[] private typeList = ["sculpture"];
    mapping(uint256 => bytes) private images;
    mapping(uint256 => string) private eachDescription;
    mapping(uint256 => Piece) private pieces;

    constructor() ERC721("PixelArtSculpture", "PAS") {
        _tokenIds.increment();
    }

    modifier metadataUnlocked(uint256 _tokenId) {
        require(_exists(_tokenId), "Query for nonexistent token");
        require(!metadataLocked[_tokenId], "Unchangeable: Metadata is Locked");
        require (msg.sender == super.ownerOf(_tokenId), "No right to change image");
        _;
    }

    modifier traitsUnlocked() {
        require(!traitsLocked, "Unchangeable: traits are Locked");
        _;
    }

    function safeMint(address to, string calldata _title, uint256[3] calldata _params) public onlyOwner{
        require(_tokenIds.current() <= maxSupply, "Exceed MaxSupply");
        require(_params[0] < colorList.length, "color parm is out of range");
        require(_params[1] < styleList.length, "style parm is out of range");
        require(_params[2] < typeList.length, "type parm is out of range");
        uint256 currentTokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(to, currentTokenId);
        setTitle(currentTokenId, _title);
        setParams(currentTokenId, _params);
    }

    function getImage(uint256 _tokenId) internal view returns (bytes memory) {
        return images[_tokenId];
    }

    function getMetadata(uint256 _tokenId) private view returns (bytes memory) {
        string memory imageURI = Base64.encode(getImage(_tokenId));
        string[3] memory eachAttribute = [
            pieces[_tokenId].colorOf, 
            pieces[_tokenId].styleOf,
            pieces[_tokenId].typeOf
        ];
        bytes memory attributes = abi.encodePacked(
            '[{"trait_type": "COLOR", "value": "', eachAttribute[0],'"}, ',
            '{"trait_type": "STYLE_OF_ART", "value": "', eachAttribute[1],'"}, ',
            '{"trait_type": "TYPE_OF_ART", "value": "', eachAttribute[2],'"}], '
        );  
        return
            abi.encodePacked(    
                '{"name": "', pieces[_tokenId].title,'",', 
                '"description": "NFT image of the original -Pixel Art Sculpture- series of works by sculptor Ichitaro Suzuki. ',
                eachDescription[_tokenId],
                '", ',
                '"attributes": ',
                attributes,
                '"image": "data:image/svg+xml;base64,',imageURI,'"}'
            );
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory output) {
        require(_exists(_tokenId), "Query for nonexistent token");
        return 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(getMetadata(_tokenId))
                )
            );
    }

    function lockMetadata(uint256 _tokenId) external onlyOwner {
        require(!metadataLocked[_tokenId], "Already Locked");
        metadataLocked[_tokenId] = true;
    }

    function lockTraits() external onlyOwner traitsUnlocked {
        traitsLocked = true;
    }

    function appendColorList(
        string memory _colorList
    ) external onlyOwner traitsUnlocked{
        colorList.push(_colorList);
    }

    function appendStyleList(
        string memory _styleList
    ) external onlyOwner traitsUnlocked{
        styleList.push(_styleList);
    }

    function appendTypeList(
        string memory _typeList
    ) external onlyOwner traitsUnlocked{
        typeList.push(_typeList);
    }

    function setDescription(uint256 _tokenId, string calldata _eachDescription) public onlyOwner metadataUnlocked(_tokenId) {
        eachDescription[_tokenId] = _eachDescription;
    }

    function setParams(uint256 _tokenId, uint256[3] calldata _params) public onlyOwner metadataUnlocked(_tokenId) {
        pieces[_tokenId].colorOf = colorList[_params[0]];
        pieces[_tokenId].styleOf = styleList[_params[1]];
        pieces[_tokenId].typeOf = typeList[_params[2]];
    }

    function setTitle(uint256 _tokenId, string memory _title) public onlyOwner metadataUnlocked(_tokenId) {
        pieces[_tokenId].title = _title;
    }

    function setImage(uint256 _tokenId, bytes calldata _svg) public onlyOwner metadataUnlocked(_tokenId) {
        images[_tokenId] = abi.encodePacked(images[_tokenId], _svg);
    }

    function deleteImage(uint256 _tokenId) public onlyOwner metadataUnlocked(_tokenId) {
        images[_tokenId] = "";
    }
}