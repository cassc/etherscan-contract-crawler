// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/BaseNFTStorage.sol";

abstract contract StateNFTStorage {
    enum Size {
        SIZE_35,
        SIZE_36,
        SIZE_37,
        SIZE_38,
        SIZE_39,
        SIZE_40,
        SIZE_41,
        SIZE_42,
        SIZE_43,
        SIZE_44
    }

    enum Edition {
        TURMOIL,
        ASPHALT,
        STELLAR,
        CITADEL
    }

    mapping(uint256 => Size) internal _tokenSizes;
    mapping(uint256 => Edition) internal _tokenEditions;
    mapping(uint256 => uint256) internal _tokenNumbers;
    mapping(uint256 => bool) internal _tokenRedeems;
}