// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

struct PoolAllocationRequest {
  uint40 poolId;
  bool skip;
  uint coverAmountInAsset;
}

struct BuyCoverParams {
  uint coverId;
  address owner;
  uint24 productId;
  uint8 coverAsset;
  uint96 amount;
  uint32 period;
  uint maxPremiumInAsset;
  uint8 paymentAsset;
  uint16 commissionRatio;
  address commissionDestination;
  string ipfsData;
}

enum ID {
  TC, // TokenController.sol
  P1, // Pool.sol
  MR, // MemberRoles.sol
  MC, // MCR.sol
  CO, // Cover.sol
  SP, // StakingProducts.sol
  PS, // LegacyPooledStaking.sol
  GV, // Governance.sol
  GW, // LegacyGateway.sol
  CL, // CoverMigrator.sol
  AS, // Assessment.sol
  CI, // IndividualClaims.sol - Claims for Individuals
  CG, // YieldTokenIncidents.sol - Claims for Groups
  // TODO: 1) if you update this enum, update lib/constants.js as well
  // TODO: 2) TK is not an internal contract!
  //          If you want to add a new contract below TK, remove TK and make it immutable in all
  //          contracts that are using it (currently LegacyGateway and LegacyPooledStaking).
  TK  // NXMToken.sol
  }

interface ICover {

  function buyCover(
    BuyCoverParams calldata params,
    PoolAllocationRequest[] calldata coverChunkRequests
  ) external payable returns (uint coverId);

  function getInternalContractAddress(ID id) external view returns (address payable);

}