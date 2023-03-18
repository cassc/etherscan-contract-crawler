// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../IAspenFeatures.sol";
import "../IAspenVersioned.sol";
import "../IMulticallable.sol";
import "../splitpayment/ISplitPayment.sol";

interface IAspenPaymentSplitterV1 is IAspenFeaturesV0, IAspenVersionedV2, IMulticallableV0, IAspenSplitPaymentV1 {}