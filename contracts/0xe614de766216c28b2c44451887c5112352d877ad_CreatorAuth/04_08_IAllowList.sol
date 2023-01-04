// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IControllable} from "./IControllable.sol";

interface IAllowList is IControllable {
    event Allow(address caller);
    event Deny(address caller);

    /// @notice Check whether the given `caller` address is allowed.
    /// @param caller The caller address.
    /// @return True if caller is allowed, false if caller is denied.
    function allowed(address caller) external view returns (bool);

    /// @notice Check whether the given `caller` address is denied.
    /// @param caller The caller address.
    /// @return True if caller is denied, false if caller is allowed.
    function denied(address caller) external view returns (bool);

    /// @notice Add a caller address to the allowlist.
    /// @param caller The caller address.
    function allow(address caller) external;

    /// @notice Remove a caller address from the allowlist.
    /// @param caller The caller address.
    function deny(address caller) external;
}