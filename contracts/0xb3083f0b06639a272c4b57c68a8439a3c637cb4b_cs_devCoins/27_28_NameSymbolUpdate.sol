// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

abstract contract NameSymbolUpdate {

    function _setStringAtStorageSlot(string memory value, uint256 storageSlot) internal {
        assembly {
            let stringLength := mload(value)

            switch gt(stringLength, 0x1F)
            case 0 {
                sstore(storageSlot, or(mload(add(value, 0x20)), mul(stringLength, 2)))
            }
            default {
                sstore(storageSlot, add(mul(stringLength, 2), 1))
                mstore(0x00, storageSlot)
                let dataSlot := keccak256(0x00, 0x20)
                for { let i := 0 } lt(mul(i, 0x20), stringLength) { i := add(i, 0x01) } {
                    sstore(add(dataSlot, i), mload(add(value, mul(add(i, 1), 0x20))))
                }
            }
        }
    }

}