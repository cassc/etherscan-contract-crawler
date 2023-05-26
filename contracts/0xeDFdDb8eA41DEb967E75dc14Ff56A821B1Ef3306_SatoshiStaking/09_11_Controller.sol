// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Controller {
    function equals(bytes memory self, bytes memory other) public pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint256 addr;
        uint256 addr2;
        assembly {
            addr := add(
                self,
                /*BYTES_HEADER_SIZE*/
                32
            )
            addr2 := add(
                other,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        equal = memoryEquals(addr, addr2, self.length);
    }

    function memoryEquals(
        uint256 addr,
        uint256 addr2,
        uint256 len
    ) public pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    function isContract(address _addr) public view returns (bool isContract) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}