// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface IIdoStorageErrors {
  error ArrayParamsInvalidLengthErr();

  error IdoStartedErr();
  error IdoClosedErr();
  
  error RoundUndefinedErr(uint256 index_);
  error RoundStartedErr(uint256 index_);
  error RoundClosedErr(uint256 index_);
  error RoundInvalidSupplyErr(uint256 index_);

  error MinInvestmentErr(uint256 investment_, uint256 min_);
  error MaxInvestmentErr(uint256 investment_, uint256 max_);
  error KycCaptRangeErr(uint256 cap_, uint256 min_, uint256 max_);

  error MainReferralRewardErr(uint256 reward_);
  error SecondaryReferralRewardErr(uint256 reward_);

  error ReferralUndefinedErr(address referral_);
  error ReferralEnabledErr(address referral_);
  error ReferralDisabledErr(address referral_);

  error CollateralsUndefinedErr();

  error NativeTransferErr();
}