//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./OpenSeaStorefrontInterface.sol";

contract BlobChecker {
    address constant private OPENSEA_STOREFRONT = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    address constant public BLOB_LAB = 0x9ac320589Def76E17C02a6436a1e8244d66998B7;

    OpenSeaStorefrontInterface internal storefront = OpenSeaStorefrontInterface(OPENSEA_STOREFRONT);

    function _freeBlobs (uint256[] memory ids) internal pure returns (bool) {
        for (uint256 index = 0; index < ids.length; index++) {
            if (! _isFreeBlob(ids[index])) return false;
        }
        return true;
    }

    function _isFreeBlob (uint256 id) internal pure returns (bool) {
        // Unclaimed Blobs
        if (
            id >= 918 && id <= 984 &&
            id != 983 // The zombie Blob is already alive :kek:
        ) {
            return true;
        }

        // Unclaimed golden Blobs
        if (id >= 993 && id <= 998) {
            return true;
        }

        return false;
    }

    // ReceivesOpenSeaBlobs
    function _isBlob (uint256 id) internal view returns (bool) {
        // Make sure it's a Blob created on the OpenSea storefront
        if (storefront.balanceOf(address(this), id) < 1) {
            return false;
        }

        // Make sure it's a Blob created by BlobLab
        if (id >> 96 != uint256(uint160(BLOB_LAB))) {
            return false;
        }
        return (id & 0xffffffffff) == 1;
    }

    function _getBlobTokenId (uint256 id) internal pure returns (uint256) {
        // Get only the token ID (without the token creator)
        uint256 _id = (id & 0xffffffffffffff0000000000) >> 40;

        // Special cases
        if (_id == 935) return 983;
        if (_id == 686) return 985;
        if (_id == 683) return 986;
        if (_id == 687) return 987;
        if (_id == 942) return 988;
        if (_id == 917) return 989;
        if (_id == 944) return 990;
        if (_id == 903) return 991;
        if (_id == 926) return 992;
        if (_id == 688) return 999;

        // Offsets (due to manual mint gaps)
        if (_id < 110) return _id - 9;
        if (_id < 190) return _id - 14;
        if (_id < 191) return _id - 20;
        if (_id < 216) return _id - 15;
        if (_id < 228) return _id - 17;
        if (_id < 335) return _id - 18;
        if (_id < 461) return _id - 19;
        if (_id < 575) return _id - 20;
        if (_id < 683) return _id - 21;
        if (_id < 686) return _id - 22;
        if (_id < 692) return _id - 25;
        if (_id < 800) return _id - 26;
        if (_id < 903) return _id - 27;
        if (_id < 917) return _id - 28;
        if (_id < 926) return _id - 29;
        if (_id < 935) return _id - 30;
        if (_id < 942) return _id - 31;
        if (_id < 944) return _id - 32;
        if (_id < 951) return _id - 33;

        revert("Token not found");
    }
}