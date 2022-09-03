// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RiumSpaces is ERC1155URIStorage, Ownable {
    
    uint256 public maxId = 1000;
    bool public metaDataFrozen;
    bool[1001] private isMSFixed; 
    string private _baseURI = "";
    mapping(uint256 => uint256) private currentSupply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC1155("") {}

    modifier notFrozen() {
        require(!metaDataFrozen, "Metadata is permanently frozen");
        _;
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        require(currentSupply[id] + amount <= maxSupply[id], "It'll exceed the max supply");
        require(currentSupply[id] != maxSupply[id], "Already reached max supply");
        currentSupply[id] += amount;
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(1 <= ids[i], "id must be in 1 to 1000");
            require(ids[i] <= maxId, "id must be in 1 to 1000");
            require(currentSupply[ids[i]] + amounts[i] <= maxSupply[ids[i]], "It'll exceed the max supply");
            require(currentSupply[ids[i]] != maxSupply[ids[i]], "Already reached max supply");
        }
        for (uint256 i = 0; i < ids.length; i++) {
            currentSupply[ids[i]] += amounts[i];
        }
        _mintBatch(to, ids, amounts, data);
    }

    function isExist(uint256 _id) internal view returns(bool) {
        return getCurrentSupply(_id) > 0;
    }

    function isfrozen() external view returns(bool) {
        return metaDataFrozen;
    }

    function isMaxSupplyFixed(uint256 _id) public view returns(bool) {
        require(1 <= _id, "id must be in 1 to 1000");
        require(_id <= maxId, "id must be in 1 to 1000");
        return isMSFixed[_id];
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

    function freeze() external onlyOwner {
        require(!metaDataFrozen, "MetaData is already frozen");
        metaDataFrozen = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner notFrozen {
        _setBaseURI(_newBaseURI);
    } 

    function setEachURI(uint256 _id, string memory _newURI) public onlyOwner notFrozen {
        require(isExist(_id), "Query for nonexistent token");
        _setURI(_id, _newURI);
    }

    function setMaxSupply(uint256 _id, uint256 _maxSupply) public onlyOwner notFrozen {
        require(!isMaxSupplyFixed(_id), "MaxSupply already fixed");
        require(_maxSupply > 0, "MaxSupply must be over 0");
        isMSFixed[_id] = true;
        _setMaxSupply(_id, _maxSupply);
    }

    function _setMaxSupply(uint256 _id, uint256 _maxSupply) internal {
        maxSupply[_id] = _maxSupply;
    }

    function getCurrentSupply(uint256 _id) public view returns(uint256) {
        return currentSupply[_id];
    }
}