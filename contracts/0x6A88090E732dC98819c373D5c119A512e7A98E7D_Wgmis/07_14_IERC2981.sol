// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// OpenZeppelin Contracts @ version 4.5.0
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC2981 interface
 *
 * @notice NFT Royalty Standard.
 *
 * See https://eips.ethereum.org/EIPS/eip-2981
 */
interface IERC2981 is IERC165 {

    /**
     * @notice Determine how much royalty is owed (if any) and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (
        address receiver,
        uint256 royaltyAmount
    );

}