// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

interface ERC721BulkifyExtensionInterface {
    function transferFromBulk(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external;

    function transferFromBulk(
        address[] memory from,
        address[] memory to,
        uint256[] memory tokenIds
    ) external;
}

/**
 * @dev Extension to add bulk operations to a standard ERC721 contract.
 */
abstract contract ERC721BulkifyExtension is
    Context,
    ERC165Storage,
    ERC721,
    ERC721BulkifyExtensionInterface
{
    constructor() {
        _registerInterface(type(ERC721BulkifyExtensionInterface).interfaceId);
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    /**
     * Useful for when user wants to return tokens to get a refund,
     * or when they want to transfer lots of tokens by paying gas fee only once.
     */
    function transferFromBulk(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "NOT_OWNER");
            _transfer(from, to, tokenIds[i]);
        }
    }

    /**
     * Useful for transferring multiple tokens from/to multiple addresses.
     */
    function transferFromBulk(
        address[] memory from,
        address[] memory to,
        uint256[] memory tokenIds
    ) public virtual {
        require(from.length == to.length, "FROM_TO_LENGTH_MISMATCH");
        require(from.length == tokenIds.length, "FROM_TOKEN_LENGTH_MISMATCH");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "NOT_OWNER");
            _transfer(from[i], to[i], tokenIds[i]);
        }
    }
}