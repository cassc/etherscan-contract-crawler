// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "rain.interface.interpreter/IInterpreterStoreV1.sol";
import "../run/LibInterpreterState.sol";
import {IERC165Upgradeable as IERC165} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/// @title RainterpreterStore
/// @notice Simplest possible `IInterpreterStoreV1` that could work.
/// Takes key/value pairings from the input array and stores each in an internal
/// mapping. `StateNamespace` is fully qualified only by `msg.sender` on set and
/// doesn't attempt to do any deduping etc. if the same key appears twice it will
/// be set twice.
contract RainterpreterStore is IInterpreterStoreV1, IERC165 {
    using LibInterpreterState for StateNamespace;

    /// Store is several tiers of sandbox.
    ///
    /// 0. Address hashed into `FullyQualifiedNamespace` is `msg.sender` so that
    ///    callers cannot attack each other
    /// 1. StateNamespace is caller-provided namespace so that expressions cannot
    ///    attack each other
    /// 2. `uint256` is expression-provided key
    /// 3. `uint256` is expression-provided value
    ///
    /// tiers 0 and 1 are both embodied in the `FullyQualifiedNamespace`.
    mapping(FullyQualifiedNamespace => mapping(uint256 => uint256))
        internal store;

    // @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override returns (bool) {
        return
            interfaceId_ == type(IInterpreterStoreV1).interfaceId ||
            interfaceId_ == type(IERC165).interfaceId;
    }

    /// @inheritdoc IInterpreterStoreV1
    function set(StateNamespace namespace_, uint256[] calldata kvs_) external {
        unchecked {
            FullyQualifiedNamespace fullyQualifiedNamespace_ = namespace_
                .qualifyNamespace();
            for (uint256 i_ = 0; i_ < kvs_.length; i_ += 2) {
                store[fullyQualifiedNamespace_][kvs_[i_]] = kvs_[i_ + 1];
            }
        }
    }

    /// @inheritdoc IInterpreterStoreV1
    function get(
        FullyQualifiedNamespace namespace_,
        uint256 key_
    ) external view returns (uint256) {
        return store[namespace_][key_];
    }
}