// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ERC721SeaDropStructsErrorsAndEvents {
  /**
   * @notice Revert with an error if mint exceeds the max supply.
   */
  error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

  /**
   * @notice An event to signify that a SeaDrop token contract was deployed.
   */
  event SeaDropTokenDeployed();

  /**
   * @notice An event to signify that a Sweep nft.
   */
  event SweepNFT(
      address indexed nftRecipient,
      uint256 indexed quantity
  );
}