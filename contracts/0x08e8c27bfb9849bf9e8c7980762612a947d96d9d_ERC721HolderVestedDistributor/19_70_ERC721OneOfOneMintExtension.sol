// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721AutoIdMinterExtension.sol";
import "./ERC721PerTokenMetadataExtension.sol";

interface ERC721OneOfOneMintExtensionInterface {
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
    Ownable,
    ERC165Storage,
    AccessControl,
    ERC721AutoIdMinterExtension,
    ERC721PerTokenMetadataExtension,
    ERC721OneOfOneMintExtensionInterface
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _registerInterface(
            type(ERC721OneOfOneMintExtensionInterface).interfaceId
        );
    }

    // ADMIN

    function mintWithTokenURIsByOwner(
        address to,
        uint256 count,
        string[] memory tokenURIs
    ) external onlyOwner {
        uint256 startingTokenId = _getNextTokenId();
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

        uint256 startingTokenId = _getNextTokenId();
        _mintTo(to, count);
        for (uint256 i = 0; i < count; i++) {
            _setTokenURI(startingTokenId + i, tokenURIs[i]);
        }
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165Storage,
            AccessControl,
            ERC721AutoIdMinterExtension,
            ERC721PerTokenMetadataExtension
        )
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage, ERC721OneOfOneMintExtensionInterface)
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