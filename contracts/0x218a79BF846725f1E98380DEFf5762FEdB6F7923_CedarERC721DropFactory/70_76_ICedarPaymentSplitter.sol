// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../ICedarFeatures.sol";
import "../ICedarVersioned.sol";
import "../splitpayment/ICedarSplitPayment.sol";

interface ICedarPaymentSplitterV2 is ICedarFeaturesV0, ICedarVersionedV2, ICedarSplitPaymentV0 {}