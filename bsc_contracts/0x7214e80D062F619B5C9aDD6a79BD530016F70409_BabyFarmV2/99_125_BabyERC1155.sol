// SPDX-License-Identifier: MIT

pragma solidity >0.6.6;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract BabyERC1155 is ERC1155, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 private _currentTokenID = 0;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => address) public creators;
    string public name;
    string public symbol;
    mapping(uint256 => string) private uris;
    string public baseMetadataURI;

    modifier onlyOwnerOrCreator(uint256 id) {
        require(msg.sender == owner() || msg.sender == creators[id], "only owner or creator can do this");
        _;
    }

    constructor(string memory _uri, string memory name_, string memory symbol_) ERC1155(_uri) {
        name = name_;
        symbol = symbol_;
        baseMetadataURI = _uri;
    }

    function setURI(string memory newuri) external {
        _setURI(newuri);
    }

    function uri(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "ERC1155#uri: NONEXISTENT_TOKEN");

        if(bytes(uris[_id]).length > 0){
            return uris[_id];
        }
        return string(abi.encodePacked(baseMetadataURI, _id.toString(), ".json"));
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function updateUri(uint256 _id, string calldata _uri) external onlyOwnerOrCreator(_id) {
        if (bytes(_uri).length > 0) {
            uris[_id] = _uri;
            emit URI(_uri, _id);
        }
        else{
            delete uris[_id];
            emit URI(string(abi.encodePacked(baseMetadataURI, _id.toString(), ".json")), _id);
        }
    }

    function createDefault(
        uint256 _maxSupply,
        uint256 _initialSupply
    ) external returns (uint256 tokenId) {
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;

        emit URI(string(abi.encodePacked(baseMetadataURI, _id.toString(), ".json")), _id);

        if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, "0x");
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        return _id;
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external returns (uint256 tokenId) {
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            uris[_id] = _uri;
            emit URI(_uri, _id);
        }
        else{
            emit URI(string(abi.encodePacked(baseMetadataURI, _id.toString(), ".json")), _id);
        }

        if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        return _id;
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }
    
    function mint(address to, uint256 _id, uint256 _quantity, bytes memory _data) public onlyOwnerOrCreator(_id) {
        uint256 tokenId = _id;
        require(tokenSupply[tokenId].add(_quantity) <= tokenMaxSupply[tokenId], "Max supply reached");
        _mint(to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function multiSafeTransferFrom(address from, address[] memory tos, uint256 id, uint256[] memory amounts, bytes memory data) external {
        require(tos.length == amounts.length, "illegal num");
        for (uint i = 0; i < tos.length; i ++) {
            safeTransferFrom(from, tos[i], id, amounts[i], data);
        }
    }
}