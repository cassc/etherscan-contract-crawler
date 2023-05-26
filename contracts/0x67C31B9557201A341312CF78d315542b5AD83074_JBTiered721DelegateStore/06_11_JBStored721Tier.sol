// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member price The minimum contribution to qualify for this tier.
  @member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @member category A category to group NFT tiers by.
  @member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
  @member useVotingUnits A flag indicating if the voting units override should be used over the price as the tier's voting units.
*/
struct JBStored721Tier {
  uint104 price;
  uint32 remainingQuantity;
  uint32 initialQuantity;
  uint40 votingUnits;
  uint24 category;
  uint16 reservedRate;
  uint8 packedBools;
}