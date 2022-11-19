// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

interface ITokenRecoverable {
    // Events for token recovery (ERC20) and (ERC721)
    event TokenRecoveredERC20(
        address indexed recipient,
        address indexed erc20,
        uint256 amount
    );
    event TokenRecoveredERC721(
        address indexed recipient,
        address indexed erc721,
        uint256 tokenId
    );

    /**
     * Allows the owner of an ERC20Club or ERC721Collective to return
     * any ERC20 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC20` event.
     *
     * Requirements:
     * - The caller must be the (Club or Collective) token contract owner.
     * @param recipient Address that erroneously sent the ERC20 token(s)
     * @param erc20 Erroneously-sent ERC20 token to recover
     * @param amount Amount to recover
     */
    function recoverERC20(
        address recipient,
        address erc20,
        uint256 amount
    ) external;

    /**
     * Allows the owner of an ERC20Club or ERC721Collective to return
     * any ERC721 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC721` event.
     *
     * Requirements:
     * - The caller must be the (Club or Collective) token contract owner.
     * @param recipient Address that erroneously sent the ERC721 token
     * @param erc721 Erroneously-sent ERC721 token to recover
     * @param tokenId The tokenId to recover
     */
    function recoverERC721(
        address recipient,
        address erc721,
        uint256 tokenId
    ) external;
}