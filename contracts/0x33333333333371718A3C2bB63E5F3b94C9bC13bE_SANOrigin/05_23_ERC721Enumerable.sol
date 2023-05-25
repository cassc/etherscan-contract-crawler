// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override (IERC165, ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(
        uint256 index
    )
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < _owners.length,
            "ERC721Enumerable: global index out of bounds"
        );
        unchecked {
            return index + _startingTokenID;
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    )
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );

        uint count;
        unchecked {
            for (uint i; i < _owners.length; i++) {
                if (owner == _owners[i]) {
                    if (count == index) return _startingTokenID + i;
                    else count++;
                }
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }
}