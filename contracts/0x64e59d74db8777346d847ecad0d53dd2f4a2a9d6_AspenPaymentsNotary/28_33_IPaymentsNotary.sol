// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../IAspenFeatures.sol";
import "../IAspenVersioned.sol";
import "../payments/IPaymentNotary.sol";

interface IAspenPaymentsNotaryV2 is IAspenFeaturesV1, IAspenVersionedV2, IPaymentNotaryV2 {}