// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
  PublicDrop,
  PrivateDrop,
  AirDrop
} from "./SeaDropStructs.sol";

interface ERC721SeaDropStructsErrorsAndEvents {
  /**
   * @notice Revert with an error if mint exceeds the max supply.
   */
  error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

  /**
   * @notice An event to signify that a SeaDrop token contract was deployed.
   */
  event SeaDropTokenDeployed();
}