/// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error InvalidTokenId(uint256 tokenId);

///
/// @dev Interface for the BitBrand Rares
///
interface IBitBrandNFT {
    function initialize(
        address deployer_,
        string memory name_,
        string memory symbol_,
        address royaltyReceiver_,
        uint256 royaltyPercentage_,
        string memory baseURI_,
        uint256 maxSupply_
    ) external;

    function safeMint(address to, uint256 tokenId) external;
}