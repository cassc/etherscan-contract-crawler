// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../config/IPlatformFeeConfig.sol";
import "../config/IOperatorFilterersConfig.sol";
import "../config/ITieredPricing.sol";

interface IGlobalConfigV0 is IOperatorFiltererConfigV0, IPlatformFeeConfigV0 {}

interface IGlobalConfigV1 is IOperatorFiltererConfigV0, ITieredPricingV0 {}

interface IGlobalConfigV2 is ITieredPricingV1 {}