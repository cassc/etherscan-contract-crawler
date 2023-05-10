// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

contract Utils {
    function getCodeSize(address target) public view returns (uint256) {
        uint256 csize;
        assembly ("memory-safe") {
            csize := extcodesize(target)
        }
        return csize;
    }

    function getCode(address addr_) public view returns (bytes memory outputCode) {
        assembly ("memory-safe") {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(addr_)
            // allocate output byte array - this could also be done without assembly
            // by using outputCode = new bytes(size)
            outputCode := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(outputCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(outputCode, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(addr_, add(outputCode, 0x20), 0, size)
        }
    }
}