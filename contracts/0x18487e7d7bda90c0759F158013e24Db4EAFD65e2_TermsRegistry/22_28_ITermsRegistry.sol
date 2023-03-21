// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.0;

import "../IAspenFeatures.sol";
import "../IAspenVersioned.sol";
import "../agreement/IAgreementsRegistry.sol";
import "../IMulticallable.sol";

interface ITermsRegistryV1 is IAspenFeaturesV0, IAspenVersionedV2, IAgreementsRegistryV1, IMulticallableV0 {}