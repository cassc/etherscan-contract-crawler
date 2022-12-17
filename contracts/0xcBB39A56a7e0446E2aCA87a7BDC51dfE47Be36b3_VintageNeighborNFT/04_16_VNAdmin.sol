// SPDX-License-Identifier: Copyright

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract VNAdmin is ERC721Enumerable, Ownable {
    string private _uri = "";
    string private _termsAndConditions = "";
    mapping(uint256 => uint256) private _levelMap;
    mapping(uint256 => uint256) private _jobCodeMap;

    event BaseURISet(string indexed baseURI);
    event TermsAndConditionsSet(string indexed termsAndConditions);

    event LevelSet(uint256 indexed tokenId, uint256 indexed level);
    event JobCodeSet(uint256 indexed tokenId, uint256 indexed jobCode);

    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
        emit BaseURISet(uri);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setLevel(uint256 tokenId, uint256 level) external onlyOwner {
        ownerOf(tokenId); // check that tokenId exists
        _levelMap[tokenId] = level;
        emit LevelSet(tokenId, level);
    }

    function getLevel(uint256 tokenId) external view returns (uint256) {
        return _levelMap[tokenId];
    }

    function setJobCode(uint256 tokenId, uint256 jobCode) external onlyOwner {
        ownerOf(tokenId); // check that tokenId exists
        _jobCodeMap[tokenId] = jobCode;
        emit JobCodeSet(tokenId, jobCode);
    }

    function getJobCode(uint256 tokenId) external view returns (uint256) {
        return _jobCodeMap[tokenId];
    }

    function setTermsAndConditions(string calldata termsAndConditions)
        external
        onlyOwner
    {
        _termsAndConditions = termsAndConditions;
        emit TermsAndConditionsSet(_termsAndConditions);
    }

    function getTermsAndConditions() external view returns (string memory) {
        return _termsAndConditions;
    }
}