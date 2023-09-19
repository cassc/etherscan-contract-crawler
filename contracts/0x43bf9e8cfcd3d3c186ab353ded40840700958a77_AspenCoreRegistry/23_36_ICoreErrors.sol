// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRegistryErrorsV0 {
    error ContractNotFound();
    error ZeroAddressError();
    error FailedToSetCoreRegistry();
    error CoreRegistryInterfaceNotSupported();
    error AddressNotContract();
}

interface ICoreRegistryErrorsV0 {
    error FailedToSetCoreRegistry();
    error FailedToSetConfigContract();
    error FailedTosetDeployerContract();
}

interface IOperatorFiltererConfigErrorsV0 {
    error OperatorFiltererNotFound();
    error InvalidOperatorFiltererDetails();
}

interface ICoreRegistryEnabledErrorsV0 {
    error CoreRegistryNotSet();
}

interface ITieredPricingErrorsV0 {
    error PlatformFeeReceiverAlreadySet();
    error InvalidAccount();
    error TierNameAlreadyExist();
    error InvalidTierId();
    error InvalidFeeType();
    error SingleTieredNamespace();
    error InvalidPercentageFee();
    error AccountAlreadyOnTier();
    error AccountAlreadyOnDefaultTier();
    error InvalidTierName();
    error InvalidFeeTypeForDeploymentFees();
    error InvalidFeeTypeForClaimFees();
    error InvalidFeeTypeForCollectorFees();
    error InvalidCurrencyAddress();
}