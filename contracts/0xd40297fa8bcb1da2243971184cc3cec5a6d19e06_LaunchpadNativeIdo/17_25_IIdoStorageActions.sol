// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './IIdoStorageState.sol';


interface IIdoStorageActions {
  /**
   * @dev Opens the ido.
   */
  function openIdo() external;

  /**
   * @dev Closes the ido.
   */
  function closeIdo() external;

  /**
   * @dev Adds new round.
   * @param priceVestingShort_  price per token unit for short vesting.
   * @param priceVestingLong_  price per token unit for long vesting.
   * @param totalSupply_  max amount of tokens available in the round.
   */
  function setupRound(uint256 priceVestingShort_, uint256 priceVestingLong_, uint256 totalSupply_) external;

  /**
   * @dev Setups default referrals.
   * @param mainReferralReward_  main reward percent.
   * @param secondaryReferralReward_  secondary reward percent.
   */
  function setupDefaultReferral(uint256 mainReferralReward_, uint256 secondaryReferralReward_) external;

  /**
   * @dev Adds referrals.
   * @param referrals_  referrals addresses.
   * @param mainRewards_  collection of main rewards.
   * @param secondaryRewards_  collection of secondary rewards.
   */
  function setupReferrals(
    address[] calldata referrals_,
    uint256[] calldata mainRewards_,
    uint256[] calldata secondaryRewards_
  ) external;

  /**
   * @dev Updates round price parameters.
   * @param index_  round index.
   * @param priceVestingShort_  price per token unit for short vesting.
   * @param priceVestingLong_  price per token unit for long vesting.
   */
  function updateRoundPrice(uint256 index_, uint256 priceVestingShort_, uint256 priceVestingLong_) external;

  /**
   * @dev Updates round supply parameters.
   * @param index_  round index.
   * @param totalSupply_  max amount of tokens available in the round.
   */
  function updateRoundSupply(uint256 index_, uint256 totalSupply_) external;

  /**
   * @dev Opens round for investment.
   * @param index_  round index.
   */
  function openRound(uint256 index_) external;

  /**
   * @dev Closes round for investment.
   * @param index_  round index.
   */
  function closeRound(uint256 index_) external;

  /**
   * @dev Sets beneficiary KYC pass.
   * @param beneficiary_  address performing the token purchase.
   * @param value_  KYC pass state.
   */
  function setKycPass(address beneficiary_, bool value_) external;

  /**
   * @dev Sets KYC pass to the beneficiaries in batches.
   * @param beneficiaries_  beneficiaries array to set the kyc for.
   * @param values_  KYC pass states.
   */
  function setKycPassBatches(address[] calldata beneficiaries_, bool[] calldata values_) external;

  /**
   * @dev Sets max investment amount.
   * @param investment_  max investment amount.
   */
  function setMaxInvestment(uint256 investment_) external;

  /**
   * @dev Sets min investment amount.
   * @param investment_  min investment amount.
   */
  function setMinInvestment(uint256 investment_) external;
  /**
   * @dev Sets KYC cap.
   * @param cap_  new cap value.
   */
  function setKycCap(uint256 cap_) external;

  /**
   * @dev Sets purchase state.
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  collateral asset.
   * @param investment_  normalized investment amount.
   * @param tokensSold_  amount of tokens purchased.
   * @param referral_  referral owner.
   * @param mainReward_  referral reward in purchase token.
   * @param tokenReward_  referral reward in ido token.
   */
  function setPurchaseState(
    address beneficiary_,
    address collateral_,
    uint256 investment_,
    uint256 tokensSold_,
    address referral_,
    uint256 mainReward_,
    uint256 tokenReward_
  ) external;

  /**
   * @dev Enables referral code.
   * @param referral_  referral owner.
   */
  function enableReferral(address referral_) external;

  /**
   * @dev Disables referral code.
   * @param referral_  referral owner.
   */
  function disableReferral(address referral_) external;

  /**
   * @dev Claims referral rewards.
   * @param collaterals_  array of collaterals tokens.
   */
  function claimRewards(address[] calldata collaterals_) external;

  /**
   * @dev Allows to recover native coin from contract.
   */
  function recoverNative() external;

  /**
   * @dev Allows to recover erc20 tokens.
   * @param token_  token address.
   * @param amount_  amount to be recovered.
   */
  function recoverERC20(address token_, uint256 amount_) external;

  /**
   * @return True if the ido is opened.
   */
  function isOpened() external view returns (bool);

  /**
   * @return True if the ido is closed.
   */
  function isClosed() external view returns (bool);

  /**
   * @return Number of rounds
   */
  function getRoundsCount() external view returns (uint256);

  /**
   * @return Active round index.
   */
  function getActiveRound() external view returns (uint256);

  /**
   * @return Round parameters by index.
   * @param index_  round index.
   */
  function getRound(uint256 index_) external view returns (IIdoStorageState.Round memory);

  /**
   * @return Total tokens sold.
   */
  function getTotalTokenSold() external view returns (uint256);

  /**
   * @return Price of the token in the active round.
   * @param vesting_  vesting of the investment.
   */
  function getPrice(IIdoStorageState.Vesting vesting_) external view returns (uint256);

  /**
   * @return Balance of purchased tokens by beneficiary.
   * @param round_  round of ido.
   * @param beneficiary_  address performing the token purchase.
   */
  function balanceOf(uint256 round_, address beneficiary_) external view returns (uint256);

  /**
   * @return Balance of reward tokens by referral.
   * @param collateral_  collateral token.
   * @param beneficiary_  address of referral.
   */
  function rewardBalanceOf(address collateral_, address beneficiary_) external view returns (uint256);

  /**
   * @return Beneficiary KYC.
   * @param beneficiary_  address performing the token purchase.
   */
  function hasKycPass(address beneficiary_) external view returns (bool);

  /**
   * @return Max investment amount.
   */
  function getMaxInvestment() external view returns (uint256);

  /**
   * @return Min investment amount.
   */
  function getMinInvestment() external view returns (uint256);

  /**
   * @return Cap according to KYC.
   * @param beneficiary_  address performing the token purchase.
   */
  function capOf(address beneficiary_) external view returns (uint256);

  /**
   * @return Cap according to max investment.
   * @param beneficiary_  address performing the token purchase.
   */
  function maxCapOf(address beneficiary_) external view returns (uint256);

  /**
   * @return KYC cap.
   */
  function getKycCap() external view returns (uint256);

  /**
   * @dev Get default referral.
   */
  function getDefaultReferral() external view returns (uint256, uint256);

  /**
   * @dev Get referral.
   * @param beneficiary_  address performing the token purchase.
   * @param referral_ referral owner.
   */
  function getReferral(address beneficiary_, address referral_) external view returns (address referral);

  /**
   * @return Get referral reward.
   * @param referral_  referral owner.
   */
  function getReferralReward(address referral_) external view returns (uint256, uint256);
}