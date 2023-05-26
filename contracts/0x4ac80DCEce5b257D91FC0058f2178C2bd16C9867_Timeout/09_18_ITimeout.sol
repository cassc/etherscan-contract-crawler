// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimeout {
  // mint error

  error InvalidCoupon();

  error InvalidWhitelist();

  error InvalidQuantity();

  error QueryForNonExistantTokenId();

  error AlreadyUsePremint();

  error AlreadyUsePrivateSalesMint();

  error MaxSupplyPrivateSaleReach();

  error MaxSupplyReach();

  error InvalidPhase();


  // fusion error

  error CallerNotOwnerOfTokenId();

  error InvalidTokenIdsForFusion();

  // claim error

  error SenderIsContract();

  error InvalidEvolution();

  error ThisTokenIdAlreadyClaim();

  error FailToTransferGameFunds();

  error InvalidUser();

  error FailToTransferClaimFunds();

  error UserAlreadyClaimForThisPhase();

  // withdraw error

  error FailToWithdraw();
}