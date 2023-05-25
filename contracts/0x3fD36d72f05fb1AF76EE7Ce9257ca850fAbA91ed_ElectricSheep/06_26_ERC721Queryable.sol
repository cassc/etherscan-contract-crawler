// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721Queryable is ERC721 {
    error OwnerIndexOutOfBounds();
    error OwnerIndexNotExist();

    uint256 public mintedAmount;
    uint256 private immutable collectionSize;

    /**
     * @notice Constructor
     * @param size the collection size
     */
    constructor(uint256 size) {
        collectionSize = size;
    }

    /**
     * @notice Returns the total amount of tokens stored by the contract
     */
    function totalSupply() public view returns (uint256) {
        return mintedAmount;
    }

    /**
     * @notice Returns a token ID owned by `owner` at a given `index` of its token list.
     * @dev This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     * @param owner token owner
     * @param index index of its token list
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        if (index >= balanceOf(owner)) {
            revert OwnerIndexOutOfBounds();
        }
    
        uint256 currentIndex = 0;
        unchecked {
            for (uint256 tokenId = 0; tokenId < collectionSize; tokenId++) {
                if (_exists(tokenId) && owner == ownerOf(tokenId)) {
                    if (currentIndex == index) {
                        return tokenId;
                    }
                    currentIndex++;
                }
            }
        }

        // Execution should never reach this point.
        revert OwnerIndexNotExist();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            mintedAmount += 1;
        }
        if (to == address(0)) {
            mintedAmount -= 1;
        }
    }
}