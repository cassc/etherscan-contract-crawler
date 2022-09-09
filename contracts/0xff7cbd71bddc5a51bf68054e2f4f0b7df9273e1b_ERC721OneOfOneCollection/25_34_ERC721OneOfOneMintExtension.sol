// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721AutoIdMinterExtension.sol";
import "./ERC721PerTokenMetadataExtension.sol";

interface IERC721OneOfOneMintExtension {
    function mintWithTokenURIsByOwner(
        address to,
        uint256 count,
        string[] memory tokenURIs
    ) external;

    function mintWithTokenURIsByRole(
        address to,
        uint256 count,
        string[] memory tokenURIs
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev Extension to allow owner to mint 1-of-1 NFTs by providing dedicated metadata URI for each token.
 */
abstract contract ERC721OneOfOneMintExtension is
    IERC721OneOfOneMintExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    AccessControl,
    ERC721AutoIdMinterExtension,
    ERC721PerTokenMetadataExtension
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function __ERC721OneOfOneMintExtension_init() internal onlyInitializing {
        __ERC721OneOfOneMintExtension_init_unchained();
    }

    function __ERC721OneOfOneMintExtension_init_unchained()
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
        uint256 startingTokenId = _currentTokenId;
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

        uint256 startingTokenId = _currentTokenId;
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
            ERC165Storage,
            AccessControl,
            ERC721CollectionMetadataExtension,
            ERC721PerTokenMetadataExtension
        )
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function name()
        public
        view
        virtual
        override(ERC721, ERC721CollectionMetadataExtension)
        returns (string memory)
    {
        return ERC721CollectionMetadataExtension.name();
    }

    function symbol()
        public
        view
        virtual
        override(ERC721, ERC721CollectionMetadataExtension)
        returns (string memory)
    {
        return ERC721CollectionMetadataExtension.symbol();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage, IERC721OneOfOneMintExtension)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        return ERC721URIStorage._burn(tokenId);
    }
}