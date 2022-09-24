// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Uint16Array {
    using BytesLib for bytes;

    function at(bytes storage self, uint256 _index) internal view returns (uint256 weight) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(0x0, self.slot)
            let start := keccak256(0x0, 0x20)

            let wordSlot := div(_index, 16)
            let offset := sub(240, mul(16, mod(_index, 16)))

            let word := sload(add(start, wordSlot))
            weight := and(shr(offset, word), 0xffff) 
        }
    }

    function append(bytes storage self, bytes memory _data) internal {
        self.concatStorage(_data);
    }
}