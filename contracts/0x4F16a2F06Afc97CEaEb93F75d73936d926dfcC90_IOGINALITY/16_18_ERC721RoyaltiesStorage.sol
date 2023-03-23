// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721RoyaltiesStorage is ERC721 {
    using Strings for uint256;

    struct Royalties {
        address[] recipients;
        uint32[] amounts;
        uint32 total;
    }

    mapping(uint256 => Royalties) private _tokenRoyalties;

    modifier correctFeesArgumentsNumber(uint256 feesLength, uint256 feesAmountsLength) {
        require(feesLength == feesAmountsLength, "Fees and fees amounts arrays must have the same length");
        _;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenRoyalties(uint256 tokenId, address[] memory _feeRecipients, uint32[] memory _feeAmounts)
        correctFeesArgumentsNumber(_feeRecipients.length, _feeAmounts.length)
        internal virtual
    {
        require(_exists(tokenId), "ERC721RoyaltiesStorage: Royalties set of nonexistent token");

        uint32 total;
        for (uint256 i = 0; i < _feeAmounts.length; i++) {
            total += _feeAmounts[i];
        }

        require(total <= 100, "Royalty amounts exceed maximum");
        require(total > 0, "Royalty amounts cannot be zero");

        _tokenRoyalties[tokenId] = Royalties(_feeRecipients, _feeAmounts, total);
    }

    function getRoyalties(uint256 tokenId) external view returns (address[] memory, uint32[] memory) {
        require(_exists(tokenId), "ERC721RoyaltiesStorage: Royalties get of nonexistent token");

        return (_tokenRoyalties[tokenId].recipients, _tokenRoyalties[tokenId].amounts);
    }

    function getRoyaltiesAmount(uint256 tokenId) external view returns (uint32) {
        require(_exists(tokenId), "ERC721RoyaltiesStorage: Royalties get of nonexistent token");

        return _tokenRoyalties[tokenId].total;
    }
}