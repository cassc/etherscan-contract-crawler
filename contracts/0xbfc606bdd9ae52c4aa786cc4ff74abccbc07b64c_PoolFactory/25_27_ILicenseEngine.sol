// SPDX-License-Identifier: No License
/**
 * @title Vendor Factory Contract
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ILicenseEngine is IERC721, IERC721Enumerable {
    struct LicenseInfo {
        uint256 maxPoolCount; // Maximum amount of pools that can be deployed with a license
        uint256 currentPoolCount; // Current amount of pools created with a license
        uint48 discount; // Discount on the amount paid to Vendor of interest made on lending
        uint48 colDiscount; // Discount on the amount paid to Vendor from collateral generated
        uint48 expiry; // Date when the license expires
    }

    function licenses(uint256 id)
        external
        view
        returns (
            uint256 maxPoolCount,
            uint256 currentPoolCount,
            uint48 discount,
            uint48 colDiscount,
            uint48 expiry
        );

    function incrementCurrentPoolCount(uint256 _lic) external;

    function exists(uint256 _tokenId) external view returns (bool);
}