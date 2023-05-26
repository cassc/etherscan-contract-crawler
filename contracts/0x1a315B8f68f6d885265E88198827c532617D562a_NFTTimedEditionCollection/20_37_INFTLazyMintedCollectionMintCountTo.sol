// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title The required interface for collections to support minting from the NFTDropMarket.
 * @dev This interface must be registered as a ERC165 supported interface.
 * @author batu-inal & HardlyDifficult
 */
interface INFTLazyMintedCollectionMintCountTo {
  function mintCountTo(uint16 count, address to) external returns (uint256 firstTokenId);

  /**
   * @notice Get the number of tokens which can still be minted.
   * @return count The max number of additional NFTs that can be minted by this collection.
   */
  function numberOfTokensAvailableToMint() external view returns (uint256 count);
}