// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.17;

import './ERC721Initializable.sol';

/**
 * @title ERC721A Queryable + ERC721Enumerable#totalSupply only to save gas
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721Queryable is ERC721Initializable {
    error ERC721Queryable__InvalidQueryRange();

    // @dev Store total number of Tokens.
    uint256 private _totalSupply;

    // @dev The tokenId of the next token to be minted.
    uint256 private _currentIndex;

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
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, 1);

        unchecked {
            if (from == address(0)) {
                _totalSupply += batchSize;
                _currentIndex += batchSize;
            } else if (to == address(0)) {
                _totalSupply -= batchSize;
            }
        }
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function nextTokenId() public view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721Queryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert ERC721Queryable__InvalidQueryRange();

            if (stop > _currentIndex) {
                stop = _currentIndex;
            }

            uint256 tokenIdsMaxLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }

            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (stop - start < tokenIdsMaxLength) {
                tokenIdsMaxLength = stop - start;
            }

            uint256 tokenIdsIdx;
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                if(_owners[i] == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721Queryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);

            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
                if(_owners[i] == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }

            return tokenIds;
        }
    }
}