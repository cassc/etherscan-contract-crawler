// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721AMinterExtension.sol";

import {IERC721PublicSaleExtension} from "../../ERC721/extensions/ERC721PublicSaleExtension.sol";

/**
 * @dev Extension to provide pre-sale and public-sale capabilities for collectors to mint for a specific price.
 */
abstract contract ERC721APublicSaleExtension is
    IERC721PublicSaleExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721AMinterExtension,
    ReentrancyGuard
{
    uint256 public publicSalePrice;
    uint256 public publicSaleMaxMintPerTx;
    bool public publicSaleStatus;

    function __ERC721APublicSaleExtension_init(
        uint256 _publicSalePrice,
        uint256 _publicSaleMaxMintPerTx
    ) internal onlyInitializing {
        __ERC721APublicSaleExtension_init_unchained(
            _publicSalePrice,
            _publicSaleMaxMintPerTx
        );
    }

    function __ERC721APublicSaleExtension_init_unchained(
        uint256 _publicSalePrice,
        uint256 _publicSaleMaxMintPerTx
    ) internal onlyInitializing {
        _registerInterface(type(IERC721PublicSaleExtension).interfaceId);

        publicSalePrice = _publicSalePrice;
        publicSaleMaxMintPerTx = _publicSaleMaxMintPerTx;
    }

    /* ADMIN */

    function setPublicSalePrice(uint256 newValue) external onlyOwner {
        publicSalePrice = newValue;
    }

    function setPublicSaleMaxMintPerTx(uint256 newValue) external onlyOwner {
        publicSaleMaxMintPerTx = newValue;
    }

    function togglePublicSaleStatus(bool isActive) external onlyOwner {
        publicSaleStatus = isActive;
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721AMinterExtension)
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