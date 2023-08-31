//SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

library DispatchersStorageLib {
    function getUint256(bytes32 position) internal view returns (uint256 data) {
        assembly {
            data := sload(position)
        }
    }

    function setUint256(bytes32 position, uint256 data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function getAddress(bytes32 position) internal view returns (address data) {
        assembly {
            data := sload(position)
        }
    }

    function setAddress(bytes32 position, address data) internal {
        assembly {
            sstore(position, data)
        }
    }
}