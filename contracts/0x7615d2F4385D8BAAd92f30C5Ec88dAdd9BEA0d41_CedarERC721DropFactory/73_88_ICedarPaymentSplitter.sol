// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "../ICedarFeatures.sol";
import "../ICedarVersioned.sol";
import "../splitpayment/ICedarSplitPayment.sol";

interface ICedarPaymentSplitterV0 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    ICedarSplitPaymentV0
{

}