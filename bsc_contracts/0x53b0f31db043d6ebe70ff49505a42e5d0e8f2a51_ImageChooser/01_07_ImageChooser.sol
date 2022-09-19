// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


contract ImageChooser is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint256 => uint256) public _selectedVersion;
    mapping(uint256 => string) public _baseURIs;
    EnumerableSet.UintSet private _validVersions;
    IERC721Enumerable immutable public token;

    constructor(IERC721Enumerable _token) {
        token = _token;
    }

    function addVersion(uint256 _version, string memory _baseURI) external onlyOwner {
        _validVersions.add(_version);
        _baseURIs[_version] = _baseURI;
    }

    function removeVersion(uint256 _version) external onlyOwner {
        _validVersions.remove(_version);
        delete _baseURIs[_version];
    }

    function selectVersion(uint256 tokenId, uint256 version) external {
        _setVersion(tokenId, version);
    }

    function selectVersios(uint256[] memory tokenIds, uint256[] memory versions) external {
        require(tokenIds.length == versions.length, "Invalud argument lengths");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _setVersion(tokenIds[i], versions[i]);
        }
    }

    function _setVersion(uint256 tokenId, uint256 version) internal {
        require(token.ownerOf(tokenId) == msg.sender, "Only owner of token");
        require(_validVersions.contains(version), "Invalid version");
        _selectedVersion[tokenId] = version;
    }

    function avaiableVersions() external view returns (uint256[] memory versions, string[] memory baseURIs) {
        versions = _validVersions.values();
        baseURIs = new string[](versions.length);
        for (uint256 i = 0; i < versions.length; ++i) {
            baseURIs[i] = _baseURIs[versions[i]];
        }
    }

    function selected(uint256 cursor, uint256 size) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        uint256 limit = token.totalSupply() - cursor;
        if (length > limit) {
            length = limit;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = selected(token.tokenByIndex(i));
        }

        return (values, cursor + length);
    }

    function selected(uint256 tokenId) public view returns (uint256) {
        uint256 version = _selectedVersion[tokenId];
        return _validVersions.contains(version) ? version : 0;
    }
}