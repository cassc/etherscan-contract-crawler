// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10 <0.9.0;

/**
 * @dev A simplified version of the delegate.cash interface
 */
interface IDelegationRegistry {
    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}