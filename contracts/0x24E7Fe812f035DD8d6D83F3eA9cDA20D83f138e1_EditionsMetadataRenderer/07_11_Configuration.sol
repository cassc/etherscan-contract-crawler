// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {IMetadataRenderer} from "../interface/IMetadataRenderer.sol";

/// @notice General configuration for NFT Minting and bookkeeping
struct Configuration {
  /// @dev Metadata renderer (uint160)
  IMetadataRenderer metadataRenderer;
  /// @dev Total size of edition that can be minted (uint160+64 = 224)
  uint64 editionSize;
  /// @dev Royalty amount in bps (uint224+16 = 240)
  uint16 royaltyBPS;
  /// @dev Funds recipient for sale (new slot, uint160)
  address payable fundsRecipient;
}