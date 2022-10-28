// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IAdapter } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { IBooster } from "../../integrations/convex/IBooster.sol";

interface IConvexV1BoosterAdapter is IAdapter, IBooster {
    /// @dev Scans the Credit Manager's allowed contracts for Convex pool
    ///      adapters and adds the corresponding phantom tokens to an internal mapping
    /// @notice Admin function. The mapping is used to determine an output token from the
    ///         pool's pid, when deposit is called with stake == true
    function updateStakedPhantomTokensMap() external;
}