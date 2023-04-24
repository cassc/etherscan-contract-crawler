// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {SalesConfiguration} from "./SalesConfiguration.sol";

/// @param erc721TransferHelper Transfer helper contract
/// @param marketFilterAddress Market filter address - Manage subscription to the for marketplace filtering based off royalty payouts.
/// @param initialOwner User that owns and can mint the edition, gets royalty and sales payouts and can update the base url if needed.
/// @param fundsRecipient Wallet/user that receives funds from sale
/// @param editionSize Number of editions that can be minted in total. If type(uint64).max, unlimited editions can be minted as an open edition.
/// @param royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
/// @param salesConfiguration The initial SalesConfiguration
/// @param metadataRenderer Renderer contract to use
/// @param metadataRendererInit Renderer data initial contract
struct DropsInitializer {
  address erc721TransferHelper;
  address marketFilterAddress;
  address initialOwner;
  address payable fundsRecipient;
  uint64 editionSize;
  uint16 royaltyBPS;
  bool enableOpenSeaRoyaltyRegistry;
  SalesConfiguration salesConfiguration;
  address metadataRenderer;
  bytes metadataRendererInit;
}