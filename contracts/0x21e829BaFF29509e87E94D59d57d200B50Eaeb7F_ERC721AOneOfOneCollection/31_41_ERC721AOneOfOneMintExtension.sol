// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721AMinterExtension.sol";
import "./ERC721APerTokenMetadataExtension.sol";

import {IERC721OneOfOneMintExtension} from "../../ERC721/extensions/ERC721OneOfOneMintExtension.sol";

/**
 * @dev Extension to allow owner to mint 1-of-1 NFTs by providing dedicated metadata URI for each token.
 */
abstract contract ERC721AOneOfOneMintExtension is
    IERC721OneOfOneMintExtension,
    AccessControl,
    ERC721AMinterExtension,
    ERC721APerTokenMetadataExtension
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function __ERC721AOneOfOneMintExtension_init() internal onlyInitializing {
        __ERC721APerTokenMetadataExtension_init();
        __ERC721AOneOfOneMintExtension_init_unchained();
    }

    function __ERC721AOneOfOneMintExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721OneOfOneMintExtension).interfaceId);
    }

    /* ADMIN */

    function mintWithTokenURIsByOwner(
        address to,
        uint256 count,
        string[] memory tokenURIs
    ) external onlyOwner {
        uint256 startingTokenId = _nextTokenId();
        _mintTo(to, count);
        for (uint256 i = 0; i < count; i++) {
            _setTokenURI(startingTokenId + i, tokenURIs[i]);
        }
    }

    function mintWithTokenURIsByRole(
        address to,
        uint256 count,
        string[] memory tokenURIs
    ) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "NOT_MINTER_ROLE");

        uint256 startingTokenId = _nextTokenId();
        _mintTo(to, count);
        for (uint256 i = 0; i < count; i++) {
            _setTokenURI(startingTokenId + i, tokenURIs[i]);
        }
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControl,
            ERC721ACollectionMetadataExtension,
            ERC721APerTokenMetadataExtension
        )
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function name()
        public
        view
        virtual
        override(ERC721A, ERC721ACollectionMetadataExtension)
        returns (string memory)
    {
        return ERC721ACollectionMetadataExtension.name();
    }

    function symbol()
        public
        view
        virtual
        override(ERC721A, ERC721ACollectionMetadataExtension)
        returns (string memory)
    {
        return ERC721ACollectionMetadataExtension.symbol();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(
            ERC721A,
            ERC721APerTokenMetadataExtension,
            IERC721OneOfOneMintExtension
        )
        returns (string memory)
    {
        return ERC721APerTokenMetadataExtension.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721A, ERC721APerTokenMetadataExtension)
    {
        return ERC721APerTokenMetadataExtension._burn(tokenId);
    }
}