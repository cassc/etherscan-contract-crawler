//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.6.12;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 * @dev Interop with other systems supporting this interface
 * @notice Original license and source here: https://github.com/Pixura/pixura-contracts
 */
interface IERC721Creator {
    /**
     * @dev Gets the creator of the _tokenId
     * @param _tokenId uint256 ID of the token
     * @return address of the creator of _tokenId
     */
    function tokenCreator(uint256 _tokenId) external view returns (address payable);
}