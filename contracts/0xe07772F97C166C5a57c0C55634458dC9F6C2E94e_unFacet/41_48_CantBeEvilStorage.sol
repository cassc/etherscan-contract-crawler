// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";

library CantBeEvilStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.unDiamond.NFT.facet.licenses.CantBeEvil.storage");

    string internal constant _BASE_LICENSE_URI = "ar://_D9kN1WrNWbCq55BSAGRbTB4bS3v8QAPTYmBThSbX3A/";

    enum LicenseVersion {
        CBE_CC0,
        CBE_ECR,
        CBE_NECR,
        CBE_NECR_HS,
        CBE_PR,
        CBE_PR_HS
    }

    struct Layout {
        mapping(uint256 => uint8) tokenLicenses; // Mapping of tokenId to license
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _setTokenLicense(uint256 tokenId, uint8 license) internal {
        require(license <= 5, "Invalid License");
        Layout storage l = layout();
        l.tokenLicenses[tokenId] = license;
    }

    function _getLicenseURI(uint256 tokenId) internal view returns (string memory) {
        Layout storage l = layout();
        return string(abi.encodePacked(_BASE_LICENSE_URI, UintUtils.toString(l.tokenLicenses[tokenId])));
    }

    function _getLicenseName(uint256 tokenId) internal view returns (string memory) {
        Layout storage l = layout();
        return _getLicenseVersionKeyByValue(l.tokenLicenses[tokenId]);
    }

    function _getLicenseVersionKeyByValue(uint8 licenseVersion) internal pure returns (string memory) {
        if (uint8(LicenseVersion.CBE_CC0) == licenseVersion) return "CBE_CC0";
        if (uint8(LicenseVersion.CBE_ECR) == licenseVersion) return "CBE_ECR";
        if (uint8(LicenseVersion.CBE_NECR) == licenseVersion) return "CBE_NECR";
        if (uint8(LicenseVersion.CBE_NECR_HS) == licenseVersion) return "CBE_NECR_HS";
        if (uint8(LicenseVersion.CBE_PR) == licenseVersion) return "CBE_PR";
        else return "CBE_PR_HS";
    }
}