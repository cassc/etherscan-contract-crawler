// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: @frankPoncelet

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/IERC165.sol";

interface IRoyalties is IERC165 {
    
    
    // Royalty support for RaribleV1
    // fees.recipient refers to either the item owner (By default) or an address where the Royalties will be received.
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    // fees.value is the royalties percentage, by default this value is 1000 on Rarible which is a 10% royalties fee.
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    // 
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    /** Called with the sale price to determine how much royalty
     *          is owed and to whom EIP2981
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256);
}