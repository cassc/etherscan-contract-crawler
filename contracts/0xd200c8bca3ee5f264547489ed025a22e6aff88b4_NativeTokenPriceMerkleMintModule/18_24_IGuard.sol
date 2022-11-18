// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Interface for a Guard that governs whether a token can be minted, burned, or
 * transferred by a particular operator, from a particular sender (`from` is
 * address 0 iff the token is being minted), to a particular recipient (`to` is
 * address 0 iff the token is being burned).
 */
interface IGuard {
    /**
     * @return True iff the transaction is allowed
     * @param operator Transaction msg.sender
     * @param from Token sender
     * @param to Token recipient
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function isAllowed(
        address operator,
        address from,
        address to,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external view returns (bool);
}