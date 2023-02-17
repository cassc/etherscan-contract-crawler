// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.16;

library StorageAPI {
    function setBytes(bytes32 key, bytes memory data) internal {
        bytes32 slot = keccak256(abi.encodePacked(key));
        assembly {
            let length := mload(data)
            switch gt(length, 0x1F)
            case 0x00 {
                sstore(key, or(mload(add(data, 0x20)), mul(length, 2)))
            }
            case 0x01 {
                sstore(key, add(mul(length, 2), 1))
                for {
                    let i := 0
                } lt(mul(i, 0x20), length) {
                    i := add(i, 0x01)
                } {
                    sstore(add(slot, i), mload(add(data, mul(add(i, 1), 0x20))))
                }
            }
        }
    }

    function setBytes32(bytes32 key, bytes32 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setAddress(bytes32 key, address a) internal {
        assembly {
            sstore(key, a)
        }
    }

    function setUint256(bytes32 key, uint256 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setInt256(bytes32 key, int256 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setBool(bytes32 key, bool val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function getBytes(bytes32 key) internal view returns (bytes memory data) {
        bytes32 slot = keccak256(abi.encodePacked(key));
        assembly {
            let length := sload(key)
            switch and(length, 0x01)
            case 0x00 {
                let decodedLength := div(and(length, 0xFF), 2)
                mstore(data, decodedLength)
                mstore(add(data, 0x20), and(length, not(0xFF)))
                mstore(0x40, add(data, 0x40))
            }
            case 0x01 {
                let decodedLength := div(length, 2)
                let i := 0
                mstore(data, decodedLength)
                for {

                } lt(mul(i, 0x20), decodedLength) {
                    i := add(i, 0x01)
                } {
                    mstore(add(add(data, 0x20), mul(i, 0x20)), sload(add(slot, i)))
                }
                mstore(0x40, add(data, add(0x20, mul(i, 0x20))))
            }
        }
    }

    function getBytes32(bytes32 key) internal view returns (bytes32 val) {
        assembly {
            val := sload(key)
        }
    }

    function getAddress(bytes32 key) internal view returns (address a) {
        assembly {
            a := sload(key)
        }
    }

    function getUint256(bytes32 key) internal view returns (uint256 val) {
        assembly {
            val := sload(key)
        }
    }

    function getInt256(bytes32 key) internal view returns (int256 val) {
        assembly {
            val := sload(key)
        }
    }

    function getBool(bytes32 key) internal view returns (bool val) {
        assembly {
            val := sload(key)
        }
    }
}