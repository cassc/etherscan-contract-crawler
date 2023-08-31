// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISuperRareRegistry {
    /**
     * @dev Get the token creator which will receive royalties of the given token
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     */
    function tokenCreator(address _contractAddress, uint256 _tokenId) external view returns (address payable);
}