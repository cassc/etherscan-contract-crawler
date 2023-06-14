// SPDX-License-Identifier: MIT
/*

  Copyright 2018 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.6.12;

import { LibEIP712 } from "./LibEIP712.sol";

library LibPermit {
    struct Permit {
        address spender; // Spender
        uint256 value; // Value
        uint256 nonce; // Nonce
        uint256 expiry; // Expiry
    }

    // Hash for the EIP712 LibPermit Schema
    //    bytes32 constant internal EIP712_PERMIT_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "Permit(",
    //        "address spender,",
    //        "uint256 value,",
    //        "uint256 nonce,",
    //        "uint256 expiry",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_PERMIT_SCHEMA_HASH =
        0x58e19c95adc541dea238d3211d11e11e7def7d0c7fda4e10e0c45eb224ef2fb7;

    /// @dev Calculates Keccak-256 hash of the permit.
    /// @param permit The permit structure.
    /// @return permitHash Keccak-256 EIP712 hash of the permit.
    function getPermitHash(Permit memory permit, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 permitHash)
    {
        permitHash = LibEIP712.hashEIP712Message(eip712ExchangeDomainHash, hashPermit(permit));
        return permitHash;
    }

    /// @dev Calculates EIP712 hash of the permit.
    /// @param permit The permit structure.
    /// @return result EIP712 hash of the permit.
    function hashPermit(Permit memory permit) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_PERMIT_SCHEMA_HASH;

        assembly {
            // Assert permit offset (this is an internal error that should never be triggered)
            if lt(permit, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(permit, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 160)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}