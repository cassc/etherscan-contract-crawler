// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721AutoIdMinterExtension.sol";

interface ERC721PublicSaleExtensionInterface {
    function setPublicSalePrice(uint256 newValue) external;

    function setPublicSaleMaxMintPerTx(uint256 newValue) external;

    function togglePublicSaleStatus(bool isActive) external;

    function mintPublicSale(address to, uint256 count) external payable;
}

/**
 * @dev Extension to provide pre-sale and public-sale capabilities for collectors to mint for a specific price.
 */
abstract contract ERC721PublicSaleExtension is
    Ownable,
    ERC165Storage,
    ERC721AutoIdMinterExtension,
    ReentrancyGuard,
    ERC721PublicSaleExtensionInterface
{
    uint256 public publicSalePrice;
    uint256 public publicSaleMaxMintPerTx;
    bool public publicSaleStatus;

    constructor(uint256 _publicSalePrice, uint256 _publicSaleMaxMintPerTx) {
        publicSalePrice = _publicSalePrice;
        publicSaleMaxMintPerTx = _publicSaleMaxMintPerTx;

        _registerInterface(
            type(ERC721PublicSaleExtensionInterface).interfaceId
        );
    }

    // ADMIN

    function setPublicSalePrice(uint256 newValue) external onlyOwner {
        publicSalePrice = newValue;
    }

    function setPublicSaleMaxMintPerTx(uint256 newValue) external onlyOwner {
        publicSaleMaxMintPerTx = newValue;
    }

    function togglePublicSaleStatus(bool isActive) external onlyOwner {
        publicSaleStatus = isActive;
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721AutoIdMinterExtension)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function mintPublicSale(address to, uint256 count)
        external
        payable
        nonReentrant
    {
        require(publicSaleStatus, "PUBLIC_SALE_NOT_ACTIVE");
        require(count <= publicSaleMaxMintPerTx, "PUBLIC_SALE_LIMIT");
        require(publicSalePrice * count <= msg.value, "INSUFFICIENT_AMOUNT");

        _mintTo(to, count);
    }
}