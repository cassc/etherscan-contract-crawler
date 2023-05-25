// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRecoverable {
    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the NFT contract by mistake and this contract
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external;

    /**
     * @notice Allows the owner to recover tokens sent to the NFT contract and this contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external;

    /**
     * @notice Allows the owner to recover ETH sent to the NFT contract ans and contract by mistake
     * @param _to: target address
     * @dev Callable by owner
     */
    function recoverEth(address payable _to) external;
}