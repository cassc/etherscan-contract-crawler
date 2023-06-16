// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.0;

import "../IAspenFeatures.sol";
import "../IAspenVersioned.sol";
import "../config/IGlobalConfig.sol";

interface IAspenCoreRegistryV1 is IAspenFeaturesV1, IAspenVersionedV2, IGlobalConfigV1, IGlobalConfigV2 {}