// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../IAspenFeatures.sol";
import "../IAspenVersioned.sol";
import "../IMulticallable.sol";
import "../splitpayment/ISplitPayment.sol";

interface IAspenPaymentSplitterV2 is IAspenFeaturesV1, IAspenVersionedV2, IMulticallableV0, IAspenSplitPaymentV2 {}