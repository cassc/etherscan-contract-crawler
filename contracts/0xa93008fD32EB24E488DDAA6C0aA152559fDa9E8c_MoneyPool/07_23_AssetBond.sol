// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '../libraries/DataStruct.sol';
import '../libraries/Math.sol';
import '../libraries/WadRayMath.sol';
import '../libraries/TimeConverter.sol';

library AssetBond {
  using WadRayMath for uint256;
  using AssetBond for DataStruct.AssetBondData;

  uint256 constant NONCE = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC00;
  uint256 constant COUNTRY_CODE =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC003FF;
  uint256 constant COLLATERAL_SERVICE_PROVIDER_IDENTIFICATION_NUMBER =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000003FFFFF;
  uint256 constant COLLATERAL_LATITUDE =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000FFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_LATITUDE_SIGNS =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_LONGITUDE =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE0000001FFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_LONGITUDE_SIGNS =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_DETAILS =
    0xFFFFFFFFFFFFFFFFFFFFFC0000000003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_CATEGORY =
    0xFFFFFFFFFFFFFFFFFFF003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant PRODUCT_NUMBER =
    0xFFFFFFFFFFFFFFFFC00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  uint256 constant NONCE_START = 0;
  uint256 constant COUNTRY_CODE_START = 10;
  uint256 constant COLLATERAL_SERVICE_PROVIDER_IDENTIFICATION_NUMBER_START = 22;
  uint256 constant COLLATERAL_LATITUDE_START = 72;
  uint256 constant COLLATERAL_LATITUDE_SIGNS_START = 100;
  uint256 constant COLLATERAL_LONGITUDE_START = 101;
  uint256 constant COLLATERAL_LONGITUDE_SIGNS_START = 129;
  uint256 constant COLLATERAL_DETAILS_START = 130;
  uint256 constant COLLATERAL_CATEGORY_START = 170;
  uint256 constant PRODUCT_NUMBER_START = 180;

  function parseAssetBondId(uint256 tokenId)
    public
    pure
    returns (DataStruct.AssetBondIdData memory)
  {
    DataStruct.AssetBondIdData memory vars;
    vars.nonce = tokenId & ~NONCE;
    vars.countryCode = (tokenId & ~COUNTRY_CODE) >> COUNTRY_CODE_START;
    vars.collateralServiceProviderIdentificationNumber =
      (tokenId & ~COLLATERAL_SERVICE_PROVIDER_IDENTIFICATION_NUMBER) >>
      COLLATERAL_SERVICE_PROVIDER_IDENTIFICATION_NUMBER_START;
    vars.collateralLatitude = (tokenId & ~COLLATERAL_LATITUDE) >> COLLATERAL_LATITUDE_START;
    vars.collateralLatitudeSign =
      (tokenId & ~COLLATERAL_LATITUDE_SIGNS) >>
      COLLATERAL_LATITUDE_SIGNS_START;
    vars.collateralLongitude = (tokenId & ~COLLATERAL_LONGITUDE) >> COLLATERAL_LONGITUDE_START;
    vars.collateralLongitudeSign =
      (tokenId & ~COLLATERAL_LONGITUDE_SIGNS) >>
      COLLATERAL_LONGITUDE_SIGNS_START;
    vars.collateralDetail = (tokenId & ~COLLATERAL_DETAILS) >> COLLATERAL_DETAILS_START;
    vars.collateralCategory = (tokenId & ~COLLATERAL_CATEGORY) >> COLLATERAL_CATEGORY_START;
    vars.productNumber = (tokenId & ~PRODUCT_NUMBER) >> PRODUCT_NUMBER_START;

    return vars;
  }

  function getAssetBondDebtData(DataStruct.AssetBondData memory assetBondData)
    public
    view
    returns (uint256, uint256)
  {
    if (assetBondData.state != DataStruct.AssetBondState.COLLATERALIZED) {
      return (0, 0);
    }

    uint256 accruedDebtOnMoneyPool = Math
    .calculateCompoundedInterest(
      assetBondData.interestRate,
      assetBondData.collateralizeTimestamp,
      block.timestamp
    ).rayMul(assetBondData.principal);

    uint256 feeOnCollateralServiceProvider = calculateFeeOnRepayment(
      assetBondData,
      block.timestamp
    );

    return (accruedDebtOnMoneyPool, feeOnCollateralServiceProvider);
  }

  struct CalculateFeeOnRepaymentLocalVars {
    TimeConverter.DateTime paymentDateTimeStruct;
    uint256 paymentDate;
    uint256 firstTermRate;
    uint256 secondTermRate;
    uint256 secondTermOverdueRate;
    uint256 thirdTermRate;
    uint256 totalRate;
  }

  function calculateFeeOnRepayment(
    DataStruct.AssetBondData memory assetBondData,
    uint256 paymentTimestamp
  ) internal pure returns (uint256) {
    CalculateFeeOnRepaymentLocalVars memory vars;

    vars.firstTermRate = Math.calculateCompoundedInterest(
      assetBondData.couponRate,
      assetBondData.loanStartTimestamp,
      assetBondData.collateralizeTimestamp
    );

    vars.paymentDateTimeStruct = TimeConverter.parseTimestamp(paymentTimestamp);
    vars.paymentDate = TimeConverter.toTimestamp(
      vars.paymentDateTimeStruct.year,
      vars.paymentDateTimeStruct.month,
      vars.paymentDateTimeStruct.day + 1
    );

    if (paymentTimestamp <= assetBondData.liquidationTimestamp) {
      vars.secondTermRate =
        Math.calculateCompoundedInterest(
          assetBondData.couponRate - assetBondData.interestRate,
          assetBondData.collateralizeTimestamp,
          paymentTimestamp
        ) -
        WadRayMath.ray();
      vars.thirdTermRate =
        Math.calculateCompoundedInterest(
          assetBondData.couponRate,
          paymentTimestamp,
          vars.paymentDate
        ) -
        WadRayMath.ray();

      vars.totalRate = vars.firstTermRate + vars.secondTermRate + vars.thirdTermRate;

      return assetBondData.principal.rayMul(vars.totalRate) - assetBondData.principal;
    }

    vars.secondTermRate =
      Math.calculateCompoundedInterest(
        assetBondData.couponRate - assetBondData.interestRate,
        assetBondData.collateralizeTimestamp,
        assetBondData.maturityTimestamp
      ) -
      WadRayMath.ray();
    vars.secondTermOverdueRate =
      Math.calculateCompoundedInterest(
        assetBondData.couponRate + assetBondData.delinquencyRate - assetBondData.interestRate,
        assetBondData.maturityTimestamp,
        paymentTimestamp
      ) -
      WadRayMath.ray();
    vars.thirdTermRate =
      Math.calculateCompoundedInterest(
        assetBondData.couponRate + assetBondData.delinquencyRate,
        paymentTimestamp,
        vars.paymentDate
      ) -
      WadRayMath.ray();

    vars.totalRate =
      vars.firstTermRate +
      vars.secondTermRate +
      vars.secondTermOverdueRate +
      vars.thirdTermRate;

    return assetBondData.principal.rayMul(vars.totalRate) - assetBondData.principal;
  }

  function getAssetBondLiquidationData(DataStruct.AssetBondData memory assetBondData)
    internal
    view
    returns (uint256, uint256)
  {
    uint256 accruedDebtOnMoneyPool = Math
    .calculateCompoundedInterest(
      assetBondData.interestRate,
      assetBondData.collateralizeTimestamp,
      block.timestamp
    ).rayMul(assetBondData.principal);

    uint256 feeOnCollateralServiceProvider = calculateDebtAmountToLiquidation(
      assetBondData,
      block.timestamp
    );

    return (accruedDebtOnMoneyPool, feeOnCollateralServiceProvider);
  }

  struct CalculateDebtAmountToLiquidationLocalVars {
    TimeConverter.DateTime paymentDateTimeStruct;
    uint256 paymentDate;
    uint256 firstTermRate;
    uint256 secondTermRate;
    uint256 totalRate;
  }

  function calculateDebtAmountToLiquidation(
    DataStruct.AssetBondData memory assetBondData,
    uint256 paymentTimestamp
  ) internal pure returns (uint256) {
    CalculateDebtAmountToLiquidationLocalVars memory vars;
    vars.firstTermRate = Math.calculateCompoundedInterest(
      assetBondData.couponRate,
      assetBondData.loanStartTimestamp,
      assetBondData.maturityTimestamp
    );

    vars.paymentDateTimeStruct = TimeConverter.parseTimestamp(paymentTimestamp);
    vars.paymentDate = TimeConverter.toTimestamp(
      vars.paymentDateTimeStruct.year,
      vars.paymentDateTimeStruct.month,
      vars.paymentDateTimeStruct.day + 1
    );

    vars.secondTermRate =
      Math.calculateCompoundedInterest(
        assetBondData.couponRate + assetBondData.delinquencyRate,
        assetBondData.maturityTimestamp,
        vars.paymentDate
      ) -
      WadRayMath.ray();
    vars.totalRate = vars.firstTermRate + vars.secondTermRate;

    return assetBondData.principal.rayMul(vars.totalRate) - assetBondData.principal;
  }
}