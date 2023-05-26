//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.6.12;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 * @dev Interop with other systems supporting this interface
 * @notice Original license and source here: https://github.com/Pixura/pixura-contracts
 */
interface IERC721TokenCreator {
    /**
     * @dev Gets the creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the ERC721 contract
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}