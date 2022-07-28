// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltiesRegistry {
    /*
    @notice Called with the sale price to determine how much royalty is owed and to whom.
    @param _contractAddress - The collection address
    @param _tokenId - the NFT asset queried for royalty information
    @param _value - the sale price of the NFT asset specified by _tokenId
    @return _receiver - address of who should be sent the royalty payment
    @return _royaltyAmount - the royalty payment amount for value sale price
    */
    function royaltyInfo(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount);
}