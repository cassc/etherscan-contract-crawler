// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member price The minimum contribution to qualify for this tier.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member category A category to group NFT tiers by.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member shouldUseReservedRateBeneficiaryAsDefault A flag indicating if the `reservedTokenBeneficiary` should be stored as the default beneficiary for all tiers.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
  @member useVotingUnits A flag indicating if the voting units override should be used over the price as the tier's voting units.
*/
struct JB721TierParams {
  uint104 price;
  uint32 initialQuantity;
  uint32 votingUnits;
  uint16 reservedRate;
  address reservedTokenBeneficiary;
  bytes32 encodedIPFSUri;
  uint24 category;
  bool allowManualMint;
  bool shouldUseReservedTokenBeneficiaryAsDefault;
  bool transfersPausable;
  bool useVotingUnits;
}