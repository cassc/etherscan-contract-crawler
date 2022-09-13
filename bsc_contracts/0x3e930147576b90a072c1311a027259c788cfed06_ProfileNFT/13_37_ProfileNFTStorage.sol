// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract ProfileNFTStorage {
    // constant
    uint256 internal constant _VERSION = 2;

    // storage
    address internal _nftDescriptor;
    address internal _namespaceOwner;
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;
    mapping(uint256 => string) internal _metadataById;
    mapping(uint256 => mapping(address => bool)) internal _operatorApproval;
    mapping(address => uint256) internal _addressToPrimaryProfile;
    mapping(uint256 => DataTypes.SubscribeStruct)
        internal _subscribeByProfileId;
    mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
        internal _essenceByIdByProfileId;
}