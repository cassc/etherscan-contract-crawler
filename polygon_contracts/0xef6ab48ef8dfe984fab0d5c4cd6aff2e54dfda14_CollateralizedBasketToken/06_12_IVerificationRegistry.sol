// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IBlacklist.sol";
import "./IKYCRegistry.sol";

/// @author Solid World
interface IVerificationRegistry is IBlacklist, IKYCRegistry {
    function isVerifiedAndNotBlacklisted(address subject) external view returns (bool);
}