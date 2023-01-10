// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./CantBeEvilStorage.sol";

abstract contract CantBeEvil {
    using CantBeEvilStorage for CantBeEvilStorage.Layout;

    function getLicenseURI(uint256 tokenId) external view returns(string memory) {
        return CantBeEvilStorage._getLicenseURI(tokenId);
    }

    function getLicenseName(uint256 tokenId) external view returns(string memory) {
        return CantBeEvilStorage._getLicenseName(tokenId);
    }

    function _setTokenLicense(uint256 tokenId, uint8 license) internal {
        CantBeEvilStorage._setTokenLicense(tokenId, license);
    }
}