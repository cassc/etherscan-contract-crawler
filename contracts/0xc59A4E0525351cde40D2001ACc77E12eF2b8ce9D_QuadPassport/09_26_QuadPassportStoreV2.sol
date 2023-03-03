import "./QuadPassportStore.sol";
import "../interfaces/IQuadReader.sol";

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

contract QuadPassportStoreV2 is QuadPassportStore {

    // Key could be:
    // 1) keccak256(userAddress, keccak256(attrType), issuerAddress)
    // 2) keccak256(DID, keccak256(attrType), issuerAddress)
    mapping(bytes32 => Attribute) internal _attributesv2;

    IQuadReader public reader;

}