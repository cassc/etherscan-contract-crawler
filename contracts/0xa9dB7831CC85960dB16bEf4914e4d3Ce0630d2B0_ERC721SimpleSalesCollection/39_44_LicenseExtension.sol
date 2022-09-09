// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import {LicenseVersion, CantBeEvil, ICantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

interface ILicenseExtension {
    function setLicenseVersion(LicenseVersion licenseVersion) external;

    function lockLicenseVersion() external;
}

/**
 * @dev Extension to signal license for this NFT collection.
 */
abstract contract LicenseExtension is
    ILicenseExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    CantBeEvil
{
    bool public licenseVersionLocked;

    constructor() CantBeEvil(LicenseVersion.CBE_PR) {}

    function __LicenseExtension_init(LicenseVersion _licenseVersion)
        internal
        onlyInitializing
    {
        __LicenseExtension_init_unchained(_licenseVersion);
    }

    function __LicenseExtension_init_unchained(LicenseVersion _licenseVersion)
        internal
        onlyInitializing
    {
        _registerInterface(type(ILicenseExtension).interfaceId);
        _registerInterface(type(ICantBeEvil).interfaceId);

        licenseVersion = _licenseVersion;
    }

    /* ADMIN */

    function setLicenseVersion(LicenseVersion _licenseVersion)
        external
        override
        onlyOwner
    {
        require(!licenseVersionLocked, "LICENSE_LOCKED");
        licenseVersion = _licenseVersion;
    }

    function lockLicenseVersion() external override onlyOwner {
        licenseVersionLocked = true;
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, CantBeEvil)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}