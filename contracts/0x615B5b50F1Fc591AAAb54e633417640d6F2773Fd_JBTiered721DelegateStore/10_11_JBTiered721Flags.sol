// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @custom:member lockReservedTokenChanges A flag indicating if reserved tokens can change over time by adding new tiers with a reserved rate.
/// @custom:member lockVotingUnitChanges A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
/// @custom:member lockManualMintingChanges A flag indicating if manual minting expectations can change over time by adding new tiers with manual minting.
/// @custom:member preventOverspending A flag indicating if payments sending more than the value the NFTs being minted are worth should be reverted.
struct JBTiered721Flags {
    bool lockReservedTokenChanges;
    bool lockVotingUnitChanges;
    bool lockManualMintingChanges;
    bool preventOverspending;
}