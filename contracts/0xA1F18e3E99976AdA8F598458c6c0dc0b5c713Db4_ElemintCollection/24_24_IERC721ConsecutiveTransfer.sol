//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
  @title ERC-2309: ERC-721 Consecutive Transfer Extension
  @dev https://github.com/ethereum/EIPs/issues/2309
 */

/* is ERC721 */
interface IERC721ConsecutiveTransfer {
  /**
    @notice This event is emitted when ownership of a consecutive batch of tokens changes by any mechanism.
    This includes minting, transferring, and burning.

    @dev The address executing the transaction MUST own all the tokens within the range of
    fromTokenId and toTokenId, or MUST be an approved operator to act on the owners behalf.
    The fromTokenId and toTokenId MUST be a consecutive range of tokens IDs.
    When minting/creating tokens, the `fromAddress` argument MUST be set to `0x0` (i.e. zero address).
    When burning/destroying tokens, the `toAddress` argument MUST be set to `0x0` (i.e. zero address).

    @param fromTokenId The token ID that begins the batch of tokens being transferred
    @param toTokenId The token ID that ends the batch of tokens being transferred
    @param fromAddress The address transferring ownership of the specified range of tokens
    @param toAddress The address receiving ownership of the specified range of tokens.
  */
  event ConsecutiveTransfer(
    uint256 indexed fromTokenId,
    uint256 toTokenId,
    address indexed fromAddress,
    address indexed toAddress
  );
}