// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

/**
 * @title IERC2981
 * @notice Interface for the NFT Royalty Standard
 */
interface IERC2981 {
    // / bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}