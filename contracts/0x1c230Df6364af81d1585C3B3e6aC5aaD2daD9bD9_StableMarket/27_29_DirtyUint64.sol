// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library DirtyUint64 {
    error DirtyUint64Error(uint256 errorCode);
    uint256 private constant _OVERFLOW_ERROR = 0;
    uint256 private constant _UNDERFLOW_ERROR = 1;

    function toDirtyUnsafe(uint64 cleanUint) internal pure returns (uint64 dirtyUint) {
        assembly {
            dirtyUint := add(cleanUint, 1)
        }
    }

    function toDirty(uint64 cleanUint) internal pure returns (uint64 dirtyUint) {
        assembly {
            dirtyUint := add(cleanUint, 1)
        }
        if (dirtyUint == 0) {
            revert DirtyUint64Error(_OVERFLOW_ERROR);
        }
    }

    function toClean(uint64 dirtyUint) internal pure returns (uint64 cleanUint) {
        assembly {
            cleanUint := sub(dirtyUint, gt(dirtyUint, 0))
        }
    }

    function addClean(uint64 current, uint64 cleanUint) internal pure returns (uint64) {
        assembly {
            current := add(add(current, iszero(current)), cleanUint)
        }
        if (current < cleanUint) {
            revert DirtyUint64Error(_OVERFLOW_ERROR);
        }
        return current;
    }

    function addDirty(uint64 current, uint64 dirtyUint) internal pure returns (uint64) {
        assembly {
            current := sub(add(add(current, iszero(current)), add(dirtyUint, iszero(dirtyUint))), 1)
        }
        if (current < dirtyUint) {
            revert DirtyUint64Error(_OVERFLOW_ERROR);
        }
        return current;
    }

    function subClean(uint64 current, uint64 cleanUint) internal pure returns (uint64 ret) {
        assembly {
            current := add(current, iszero(current))
            ret := sub(current, cleanUint)
        }
        if (current < ret || ret == 0) {
            revert DirtyUint64Error(_UNDERFLOW_ERROR);
        }
    }

    function subDirty(uint64 current, uint64 dirtyUint) internal pure returns (uint64 ret) {
        assembly {
            current := add(current, iszero(current))
            ret := sub(add(current, 1), add(dirtyUint, iszero(dirtyUint)))
        }
        if (current < ret || ret == 0) {
            revert DirtyUint64Error(_UNDERFLOW_ERROR);
        }
    }

    function sumPackedUnsafe(
        uint256 packed,
        uint256 from,
        uint256 to
    ) internal pure returns (uint64 ret) {
        packed = packed >> (from << 6);
        unchecked {
            for (uint256 i = from; i < to; ++i) {
                assembly {
                    let element := and(packed, 0xffffffffffffffff)
                    ret := add(ret, add(element, iszero(element)))
                    packed := shr(64, packed)
                }
            }
        }
        assembly {
            ret := sub(ret, sub(to, from))
        }
    }
}