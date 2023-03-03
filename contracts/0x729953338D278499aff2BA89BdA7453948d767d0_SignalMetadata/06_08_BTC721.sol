// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;

struct Ordinal {
    string inscriptionId;
    uint256 inscriptionNum;
}

abstract contract BTC721 {
    mapping(uint256 => Ordinal) public tokenIdToOrdinal;
    mapping(uint256 => uint32[8]) public tokenIdToTraits;
    mapping(string => bool) public inscriptionIdSet;

    function _setTokenIdToOrdinal(uint256 _tokenId, Ordinal memory _ordinal) 
        internal
    {
        if(bytes(tokenIdToOrdinal[_tokenId].inscriptionId).length != 0) 
            revert CanNotSetIfMappingAlreadyExists(); 
        if(inscriptionIdSet[_ordinal.inscriptionId]) 
            revert InscriptionIdAlreadySet();

        tokenIdToOrdinal[_tokenId] = _ordinal;
        inscriptionIdSet[_ordinal.inscriptionId] = true;
    }

    function _setTokenIdToTraits(uint256 _tokenId, uint32[8] memory _traits) 
        internal
    {
        tokenIdToTraits[_tokenId] = _traits;
    }

    function getOrdinal(uint256 _tokenId) public view returns (Ordinal memory) {
        return tokenIdToOrdinal[_tokenId];
    }

    function getTraits(uint256 _tokenId) public view returns (uint32[8] memory) {
        return tokenIdToTraits[_tokenId];
    }

}

error CanNotSetIfMappingAlreadyExists();
error InscriptionIdAlreadySet();