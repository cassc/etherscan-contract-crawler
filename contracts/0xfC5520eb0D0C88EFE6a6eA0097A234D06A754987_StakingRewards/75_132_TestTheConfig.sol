// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/GoldfinchConfig.sol";

contract TestTheConfig {
  address public poolAddress = 0xBAc2781706D0aA32Fb5928c9a5191A13959Dc4AE;
  address public clImplAddress = 0xc783df8a850f42e7F7e57013759C285caa701eB6;
  address public goldfinchFactoryAddress = 0x0afFE1972479c386A2Ab21a27a7f835361B6C0e9;
  address public fiduAddress = 0xf3c9B38c155410456b5A98fD8bBf5E35B87F6d96;
  address public creditDeskAddress = 0xeAD9C93b79Ae7C1591b1FB5323BD777E86e150d4;
  address public treasuryReserveAddress = 0xECd9C93B79AE7C1591b1fB5323BD777e86E150d5;
  address public trustedForwarderAddress = 0x956868751Cc565507B3B58E53a6f9f41B56bed74;
  address public cUSDCAddress = 0x5B281A6DdA0B271e91ae35DE655Ad301C976edb1;
  address public goldfinchConfigAddress = address(8);
  address public fiduUSDCCurveLPAddress = 0x55A8a39bc9694714E2874c1ce77aa1E599461E18;
  address public tranchedPoolImplementationRepositoryAddress = address(9);
  address public withdrawalRequestTokenAddress = address(10);

  function validateTheEnums(address configAddress) public {
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.TransactionLimit), 1);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.TotalFundsLimit), 2);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.MaxUnderwriterLimit), 3);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.ReserveDenominator), 4);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.WithdrawFeeDenominator), 5);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.LatenessGracePeriodInDays), 6);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.LatenessMaxDays), 7);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.DrawdownPeriodInSeconds), 8);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.TransferRestrictionPeriodInDays), 9);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.LeverageRatio), 10);
    GoldfinchConfig(configAddress).setNumber(
      uint256(ConfigOptions.Numbers.SeniorPoolWithdrawalCancelationFeeInBps),
      11
    );

    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.Fidu), fiduAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.Pool), poolAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.CreditDesk), creditDeskAddress);
    GoldfinchConfig(configAddress).setAddress(
      uint256(ConfigOptions.Addresses.GoldfinchFactory),
      goldfinchFactoryAddress
    );
    GoldfinchConfig(configAddress).setAddress(
      uint256(ConfigOptions.Addresses.TrustedForwarder),
      trustedForwarderAddress
    );
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.CUSDCContract), cUSDCAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.GoldfinchConfig), goldfinchConfigAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.FiduUSDCCurveLP), fiduUSDCCurveLPAddress);
    GoldfinchConfig(configAddress).setAddress(
      uint256(ConfigOptions.Addresses.TranchedPoolImplementationRepository),
      tranchedPoolImplementationRepositoryAddress
    );
    GoldfinchConfig(configAddress).setAddress(
      uint256(ConfigOptions.Addresses.WithdrawalRequestToken),
      withdrawalRequestTokenAddress
    );

    GoldfinchConfig(configAddress).setTreasuryReserve(treasuryReserveAddress);
  }
}