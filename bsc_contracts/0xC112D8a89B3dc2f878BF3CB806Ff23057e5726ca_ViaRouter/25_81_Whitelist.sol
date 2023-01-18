// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

library Whitelist {
    /// STORAGE

    bytes32 internal constant NAMESPACE = keccak256("com.via.whitelist");

    struct WhitelistStorage {
        mapping(address => bool) whitelist;
    }

    /// FUNCTIONS

    /// @notice Returns if target contract is allowed
    /// @param target Address of the target contract
    /// @return _ True if allowed, false otherwise
    function isWhitelisted(address target) internal view returns (bool) {
        return _getStorage().whitelist[target];
    }

    /// @notice Function that sets whitelist state of target contract
    /// @param target Address of the target contract
    /// @param whitelisted True if allowed, false otherwise
    function setWhitelisted(address target, bool whitelisted) internal {
        _getStorage().whitelist[target] = whitelisted;
    }

    /// @notice Function that gets shared storage struct
    /// @return wls Storage struct
    function _getStorage()
        internal
        pure
        returns (WhitelistStorage storage wls)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            wls.slot := position
        }
    }
}