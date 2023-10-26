// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface ILaunchpadErc20IdoErrors {
  error IdoClosedErr();
  error RoundClosedErr();

  error ExceededRoundAllocationErr();

  error BeneficiaryNullAddressErr();
  error InvestmentNullErr();
  error IvalidReferralErr();
  error MinInvestmentErr(uint256 investment_, uint256 min_);
  error MaxInvestmentErr(uint256 investment_, uint256 max_);

  error IdoStorageNullAddressErr();
  error WalletNullAddressErr();
  error CollateralNullAddressErr();
  error CollateralUndefinedErr();

  error NativeTransferErr();
}