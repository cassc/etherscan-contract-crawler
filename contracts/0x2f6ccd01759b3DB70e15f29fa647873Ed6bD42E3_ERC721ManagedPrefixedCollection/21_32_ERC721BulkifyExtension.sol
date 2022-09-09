// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721BulkifyExtension {
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
    IERC721BulkifyExtension,
    Initializable,
    ERC165Storage
{
    function __ERC721BulkifyExtension_init() internal onlyInitializing {
        __ERC721BulkifyExtension_init_unchained();
    }

    function __ERC721BulkifyExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721BulkifyExtension).interfaceId);
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage)
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
            IERC721(address(this)).transferFrom(from, to, tokenIds[i]);
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
            IERC721(address(this)).transferFrom(from[i], to[i], tokenIds[i]);
        }
    }
}