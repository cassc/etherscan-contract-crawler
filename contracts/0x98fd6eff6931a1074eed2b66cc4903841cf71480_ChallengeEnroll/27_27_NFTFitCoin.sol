// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./access/AccessProtected.sol";

contract FitcoinNFT is ERC721, AccessProtected {
    using SafeMath for uint256;
    string private baseURI;

    mapping(address => mapping(uint256 => uint256)) private _ownerIdIndex;
    mapping(address => uint256[]) private _ownerIds;

    constructor(string memory name, string memory symbol, string memory _baseUri) ERC721(name, symbol) {
        baseURI = _baseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory extension = ".json";
        string memory uri = super.tokenURI(tokenId);
        bytes memory tokenuri = abi.encodePacked(uri, extension);
        
        return string(tokenuri);
    }

    function mint(address to, uint256 tokenId) public onlyAdmin {
        _mint(to, tokenId);
         if (!_ownerIdExists(to, tokenId)) {
            _addOwnerId(to, tokenId);
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        
    }

    function _transfer(address from, address to,uint256 id)internal virtual override{
        if (_ownerIdExists(from, id)) {
            _deleteOwnerId(from, id);
        }
        if (!_ownerIdExists(to, id)) {
            _addOwnerId(to, id);
        }
        super._transfer(from, to, id);
    }

    // function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
    //     return super._isApprovedOrOwner(spender, tokenId) || getApproved(tokenId) == admin;
    // }

    function getOwnerIds(address owner) public view returns (uint256[] memory) {
        return _ownerIds[owner];
    }

    function getOwnerIdIndex(address owner, uint256 id) public view returns (uint256) {
        return _ownerIdIndex[owner][id];
    }

    function _deleteOwnerId(address owner, uint256 id) internal {
        uint256 lastIndex = _ownerIds[owner].length.sub(1);
        uint256 lastId = _ownerIds[owner][lastIndex];
        if (id == lastId) {
        _ownerIdIndex[owner][id] = 0;
        _ownerIds[owner].pop();
        } else {
        uint256 indexOfId = _ownerIdIndex[owner][id];
        _ownerIdIndex[owner][id] = 0;

        _ownerIds[owner][indexOfId] = lastId;
        _ownerIdIndex[owner][lastId] = indexOfId;
        _ownerIds[owner].pop();
        }
    }

    function _addOwnerId(address owner, uint256 id) internal {
        uint256 len = _ownerIds[owner].length;
        _ownerIdIndex[owner][id] = len;
        _ownerIds[owner].push(id);
    }

    function _ownerIdExists(address owner, uint256 id) internal view returns (bool) {
        if (_ownerIds[owner].length == 0) return false;
        uint256 index = _ownerIdIndex[owner][id];
        return id == _ownerIds[owner][index];
    }
}