// SPDX-License-Identifier: Apache-2.0
// Copyright © 2020 UBISOFT

pragma solidity ^0.5.0;

import "./ERC721Leveled.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";

/**
* @notice The POPO token is rewarded to every address who claimed the Rabbids Token.
*/
contract Popo is
    ERC721,
    ERC721Enumerable,
    ERC721Leveled
{
    // Keep track of the minted token per owner, per serie (the serie is the Rabbid id) and per level
    // owner => serie => level => popo token id
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _tokenIdPerOwnerSerieAndLevel;

    constructor(string memory _name, string memory _symbol, uint8 maxLevelURI)
        public
        ERC721Leveled(_name, _symbol, maxLevelURI)
    {}

    /**
    * @notice Reward an address with a POPO token
    * @dev If the receiver already owns a POPO of this level and serie, do not mint any token
    * @param receiver The address that will receive the POPO token
    * @param serie The Rabbid token id
    * @param level The level that will be set on the token
    */
    function reward(address receiver, uint256 serie, uint256 level)
        public
        onlyMinter
        returns (uint256)
    {
        uint256 existingTokenId = _tokenIdPerOwnerSerieAndLevel[receiver][serie][level];
        if (existingTokenId > 0) {
            return existingTokenId;
        }

        uint256 _tokenIds = totalSupply() + 1;
        require(_tokenIds > 0, "Overflow!");
        uint256 tokenId = _tokenIds;

        _mint(receiver, tokenId);
        _setLevel(tokenId, level);
        _setSerie(tokenId, serie);

        _tokenIdPerOwnerSerieAndLevel[receiver][serie][level] = tokenId;

        return tokenId;
    }

    /**
    * @notice Prevents the POPO token from being transferred to another address
    **/
    function _transferFrom(address, address, uint256) internal {
        revert("You can't transfer the POPO token");
    }
}