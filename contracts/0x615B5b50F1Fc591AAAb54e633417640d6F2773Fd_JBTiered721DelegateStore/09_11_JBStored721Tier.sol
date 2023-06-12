// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @custom:member price The minimum contribution to qualify for this tier.
/// @custom:member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
/// @custom:member initialQuantity The initial `remainingAllowance` value when the tier was set.
/// @custom:member votingUnits The amount of voting significance to give this tier compared to others.
/// @custom:member category A category to group NFT tiers by.
/// @custom:member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
/// @custom:member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
/// @custom:member transfersPausable A flag indicating if transfers from this tier can be pausable. 
/// @custom:member useVotingUnits A flag indicating if the voting units override should be used over the price as the tier's voting units.
struct JBStored721Tier {
    uint104 price;
    uint32 remainingQuantity;
    uint32 initialQuantity;
    uint40 votingUnits;
    uint24 category;
    uint16 reservedRate;
    uint8 packedBools;
}