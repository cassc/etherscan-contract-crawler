//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Sequencial.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This is a no storage implemntation of the optional extension {ERC721}
 * defined in the EIP that adds enumerability of all the token ids in the
 * contract as well as all token ids owned by each account. These functions
 * are mainly for convienence and should NEVER be called from inside a
 * contract on the chain.
 */
abstract contract ERC721SeqEnumerable is ERC721Sequencial, IERC721Enumerable {
    address constant zero = address(0);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Sequencial)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        uint256 length = _owners.length;

        unchecked {
            for (; tokenId < length; ++tokenId) {
                if (_owners[tokenId] == owner) {
                    if (index-- == 0) {
                        break;
                    }
                }
            }
        }

        require(
            tokenId < length,
            "ERC721Enumerable: owner index out of bounds"
        );
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply()
        public
        view
        virtual
        override
        returns (uint256 supply)
    {
        unchecked {
            uint256 length = _owners.length;
            for (uint256 tokenId = 0; tokenId < length; ++tokenId) {
                if (_owners[tokenId] != zero) {
                    ++supply;
                }
            }
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        uint256 length = _owners.length;

        unchecked {
            for (; tokenId < length; ++tokenId) {
                if (_owners[tokenId] != zero) {
                    if (index-- == 0) {
                        break;
                    }
                }
            }
        }

        require(
            tokenId < length,
            "ERC721Enumerable: global index out of bounds"
        );
    }

    /**
     * @dev Get all tokens owned by owner.
     */
    function ownerTokens(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = ERC721Sequencial.balanceOf(owner);
        require(tokenCount != 0, "ERC721Enumerable: owner owns no tokens");

        uint256 length = _owners.length;
        uint256[] memory tokenIds = new uint256[](tokenCount);
        unchecked {
            uint256 i = 0;
            for (uint256 tokenId = 0; tokenId < length; ++tokenId) {
                if (_owners[tokenId] == owner) {
                    tokenIds[i++] = tokenId;
                }
            }
        }

        return tokenIds;
    }
}