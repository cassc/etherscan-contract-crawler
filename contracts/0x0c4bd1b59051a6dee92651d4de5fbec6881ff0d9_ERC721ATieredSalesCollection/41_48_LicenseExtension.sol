// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Adopted from "@a16z/contracts/licenses/CantBeEvil.sol"
interface ICantBeEvil {
    function getLicenseURI() external view returns (string memory);

    function getLicenseName() external view returns (string memory);
}

interface ILicenseExtension {
    enum LicenseVersion {
        CBE_CC0,
        CBE_ECR,
        CBE_NECR,
        CBE_NECR_HS,
        CBE_PR,
        CBE_PR_HS,
        CUSTOM,
        UNLICENSED
    }

    error LicenseLocked();

    function setLicenseVersion(LicenseVersion licenseVersion) external;

    function lockLicenseVersion() external;
}

/**
 * @dev Extension to signal license for this NFT collection.
 */
abstract contract LicenseExtension is
    ILicenseExtension,
    ICantBeEvil,
    Initializable,
    Ownable,
    ERC165Storage
{
    using Strings for uint256;
    string internal constant A16Z_BASE_LICENSE_URI =
        "ar://_D9kN1WrNWbCq55BSAGRbTB4bS3v8QAPTYmBThSbX3A/";

    LicenseVersion public licenseVersion;
    string public customLicenseURI;
    string public customLicenseName;
    bool public licenseVersionLocked;

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

    function setCustomLicense(
        string calldata _customLicenseName,
        string calldata _customLicenseURI
    ) external onlyOwner {
        if (licenseVersionLocked) {
            revert LicenseLocked();
        }

        licenseVersion = LicenseVersion.CUSTOM;
        customLicenseName = _customLicenseName;
        customLicenseURI = _customLicenseURI;
    }

    function setLicenseVersion(LicenseVersion _licenseVersion)
        external
        override
        onlyOwner
    {
        if (licenseVersionLocked) {
            revert LicenseLocked();
        }

        licenseVersion = _licenseVersion;
    }

    function lockLicenseVersion() external override onlyOwner {
        licenseVersionLocked = true;
    }

    /* PUBLIC */

    function getLicenseURI() public view returns (string memory) {
        if (licenseVersion == LicenseVersion.CUSTOM) {
            return customLicenseURI;
        }
        if (licenseVersion == LicenseVersion.UNLICENSED) {
            return "";
        }

        return
            string.concat(
                A16Z_BASE_LICENSE_URI,
                uint256(licenseVersion).toString()
            );
    }

    function getLicenseName() public view returns (string memory) {
        if (licenseVersion == LicenseVersion.CUSTOM) {
            return customLicenseName;
        }
        if (licenseVersion == LicenseVersion.UNLICENSED) {
            return "";
        }

        if (LicenseVersion.CBE_CC0 == licenseVersion) return "CBE_CC0";
        if (LicenseVersion.CBE_ECR == licenseVersion) return "CBE_ECR";
        if (LicenseVersion.CBE_NECR == licenseVersion) return "CBE_NECR";
        if (LicenseVersion.CBE_NECR_HS == licenseVersion) return "CBE_NECR_HS";
        if (LicenseVersion.CBE_PR == licenseVersion) return "CBE_PR";
        else return "CBE_PR_HS";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}