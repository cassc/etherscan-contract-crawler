//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IGenericDroppableStorage {
    // Update one token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: bool - was the trait actually opened?
    function addTraitToToken(uint16 _tokenId) external returns(bool);

    // Update multiple token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: number of tokens actually set (not counting tokens already had the trait opened)
    function addTraitOnMultiple(uint16[] memory tokenIds) external returns(uint16 changes);

    // Was the trait activated (meaning it has non zero uint8 value)
    function hasTrait(uint16 _tokenId) external view returns(bool);

    // // Was the trait activated (meaning it has non zero uint8 value) on multiple token
    // function haveTrait(uint16[] memory _tokenId) external view returns(bool[] memory);

    // Read the generic part of the trait (the uint8 status value)
    function getUint8Value(uint16 _tokenId) external view returns(uint8);

    // Read the generic part of the trait for multiple tokens (the uint8 status value)
    function getUint8Values(uint16[] memory _tokenIds) external view returns (uint8[] memory);
}