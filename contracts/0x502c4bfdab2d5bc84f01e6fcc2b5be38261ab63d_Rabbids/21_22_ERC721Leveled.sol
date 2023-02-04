// SPDX-License-Identifier: Apache-2.0
// Copyright © 2020 UBISOFT

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/access/roles/MinterRole.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

/**
* @notice Extension of the ERC721Metadata contract that allows setting dynamic token URI according to a level
*/
contract ERC721Leveled is ERC721Metadata, IERC721Enumerable, MinterRole, Ownable {

    // Data describing a Token
    struct TokenData {
        uint256 serie;
        uint256 level;
    }
    
    // Data for each tokenId
    mapping(uint256 => TokenData) private _tokenData;

    // URI event from eip-1155 to force metadata updates in asset browsers
    event URI(string _value, uint256 indexed _id);

    // Last valid token level
    uint256 internal _maxLevel;

    constructor(string memory name, string memory symbol, uint256 maxLevel) public ERC721Metadata(name, symbol) {
        _maxLevel = maxLevel;
    }

    /**
     * @notice The corresponding URI for a token
     * @param tokenId The token id
     * @return An ipfs URI beginning with ipfs://
     *
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Leveled: URI query for nonexistent token"
        );
        return _tokenURI(tokenId);
    }
    
    /**
     * @notice Retrieve the data that describes a Token
     * @param tokenId uint256 Id of the token to be retrieved
     * @return (uint256 serie, uint256 level) Data that describes the token
     */
    function tokenData(uint256 tokenId) external view returns (uint serie, uint256 level) {
        require(
            _exists(tokenId),
            "ERC721Leveled: query for nonexistent token"
        );
        return (_tokenData[tokenId].serie, _tokenData[tokenId].level);
    }

    /**
    * @notice The current level of a token
    * @param tokenId The token id
    * @return The token level
    */
    function tokenLevel(uint256 tokenId) external view returns (uint256 level) {
        require(
            _exists(tokenId),
            "ERC721Leveled: Level query for nonexistent token"
        );
        return _tokenData[tokenId].level;
    }

    /**
    * @notice The current serie of a token
    * @param tokenId The token id
    * @return The token serie
    */
    function tokenSerie(uint256 tokenId) external view returns (uint256 level) {
        require(
            _exists(tokenId),
            "ERC721Leveled: Level query for nonexistent token"
        );
        return _tokenData[tokenId].serie;
    }

    /**
    * @notice Returns the maximum level a token can reach
    */
    function maxLevel() external view returns (uint256 level) {
        return _maxLevel;
    }

    /**
     * @notice onlyOwner function to set the ipfs base uri
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _setBaseURI(uri);
        for (uint256 id = 1; id <= totalSupply(); id++) {
            emit URI(_tokenURI(id), id);
        }
    }

    /**
    * @notice Updates the maximum level for the token
    */
    function setMaxLevel(uint256 level) public onlyOwner {
        require(level > _maxLevel, "Cannot reduce the max level");
        _maxLevel = level;
    }

    /**
    * @notice Builds the token URI string corresponding to a token id at the current level
    * @param tokenId The token id
    * @return The URI string
    */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        uint256 level = _tokenData[tokenId].level;
        uint256 serie = _tokenData[tokenId].serie;
        return string(
            abi.encodePacked(this.baseURI(),
            _uint2str(serie),
            _uint2str(level),
            ".json"
        ));
    }

    /**
    * @notice Internal call to update the level of a token
    * @param tokenId The token id
    * @param level The level
    */
    function _setLevel(uint256 tokenId, uint256 level) internal {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        require(level <= _maxLevel, "ERC721Leveled: Level out of bounds");
        _tokenData[tokenId].level = level;
        emit URI(_tokenURI(tokenId), tokenId);
    }

    /**
    * @notice Internal call to update the token serie
    * @param tokenId The token to update
    * @param serie The serie
    */
    function _setSerie(uint256 tokenId, uint256 serie) internal {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        require(serie > 0 && serie < 6, "ERC721Leveled: Serie out of bounds");
        require(
            _tokenData[tokenId].serie != serie,
            "ERC721Leveled: cannot update to same serie"
        );
        _tokenData[tokenId].serie = serie;
    }

    /**
    * @notice Convert uint256 to string
    *         Taken from https://github.com/arcadeum/multi-token-standard/blob/master/contracts/tokens/ERC1155/ERC1155Metadata.sol#L66
    * @param _i Unsigned integer to convert to string
    */
    function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 ii = _i;
        uint256 len;

        // Get number of bytes
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;

        // Get each individual ASCII
        while (ii != 0) {
            bstr[k--] = byte(uint8(48 + ii % 10));
            ii /= 10;
        }

        // Convert to string
        return string(bstr);
    }
}