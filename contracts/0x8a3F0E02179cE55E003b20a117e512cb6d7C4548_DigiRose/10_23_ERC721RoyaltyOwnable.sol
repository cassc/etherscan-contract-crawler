// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Royalty.sol";

/**
 * @dev Ownable Royalty ERC721 Contract
 *
 *      ERC721RoyaltyOwnable
 *          <= ERC721Royalty
 *          <= ERC721Enumerable
 *          <= ERC721
 */
abstract contract ERC721RoyaltyOwnable is ERC721Royalty, Ownable {
    constructor(address newOwner_) {
        transferOwnership(newOwner_);
    }

    /**
     * @dev See {IERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(
        address receiver_,
        uint96 feeNumerator_
    ) external onlyOwner {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    /**
     * @dev See {IERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {IERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId_,
        address receiver_,
        uint96 feeNumerator_
    ) external onlyOwner {
        _setTokenRoyalty(tokenId_, receiver_, feeNumerator_);
    }

    /**
     * @dev See {IERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId_) external onlyOwner {
        _resetTokenRoyalty(tokenId_);
    }
}
