// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library BannersStorage {


    struct MintConfig {
        uint256 claimEpoch;
        uint256 allowEpoch;
        uint256 allowPrice;
        uint256 allowLimit;
        uint256 publicEpoch;
        uint256 publicPrice;
        uint256 publicLimit;
        uint256 totalSupply;
        address signer;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================
        MintConfig _mintConfig;
        string _baseURI;
        mapping(address => uint256) _allowMints;
        mapping(address => uint256) _publicMints;
        mapping(uint256 => uint256) _legacyIdToTokenId;
        mapping(uint256 => uint256) _tokenIdToLegacyId;
        mapping(uint256 => uint256) _tokenIdToNewId;
        uint256 _toll;
        uint256 _minted;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('Banners.storage.Banners');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}