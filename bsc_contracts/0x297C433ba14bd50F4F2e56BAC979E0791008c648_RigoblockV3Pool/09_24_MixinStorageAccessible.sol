// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../../interfaces/pool/IStorageAccessible.sol";

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
abstract contract MixinStorageAccessible is IStorageAccessible {
    /// @inheritdoc IStorageAccessible
    function getStorageAt(uint256 offset, uint256 length) public view override returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /// @inheritdoc IStorageAccessible
    function getStorageSlotsAt(uint256[] memory slots) public view override returns (bytes memory) {
        bytes memory result = new bytes(slots.length * 32);
        for (uint256 index = 0; index < slots.length; index++) {
            uint256 slot = slots[index];
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(slot)
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }
}