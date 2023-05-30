// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "rain.interface.orderbook/IOrderBookV2.sol";

/// @title LibOrder
/// @notice Consistent handling of `Order` for where it matters w.r.t.
/// determinism and security.
library LibOrder {
    /// Hashes `Order` in a secure and deterministic way. Uses abi.encode rather
    /// than abi.encodePacked to guard against potential collisions where many
    /// inputs encode to the same output bytes.
    /// @param order_ The order to hash.
    /// @return The hash of `order_` as a `uint256` rather than `bytes32`.
    function hash(Order memory order_) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(order_)));
    }
}