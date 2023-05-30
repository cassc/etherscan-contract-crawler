// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableV2 is ERC721, IERC721Enumerable {
    address[] private _owners;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override
        returns (uint256 tokenId) {
            require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
            uint count;
            for(uint i; i < _owners.length; i++) {
                if(owner == _owners[i]) {
                    if(count == index) return _ownerIndexToTokenId(i);
                    else count++;
                }
            }
            require(false, "ERC721Enumerable: cannot find owner for token");
        }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(_exists(_ownerIndexToTokenId(index)), "ERC721Enumerable: global index out of bounds");
        return _ownerIndexToTokenId(index);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToOwnerEnumeration(to);
        } else if (to != from) {
            _updateTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     */
    function _addTokenToOwnerEnumeration(address to) private {
        _owners.push(to);
    }

    function _updateTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _owners[_tokenIdToOwnerIndex(tokenId)] = to;
    }

    function _tokenIdToOwnerIndex(uint256 tokenId) private pure returns (uint256) {
        return tokenId - 1;
    }

    function _ownerIndexToTokenId(uint256 index) private pure returns (uint256) {
        return index + 1;
    }
}