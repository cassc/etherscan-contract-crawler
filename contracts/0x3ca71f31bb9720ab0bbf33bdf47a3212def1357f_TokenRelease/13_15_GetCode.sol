// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.4;

/// @notice Get code library from the Solidity docs.
library GetCode {
    /// @dev Get the size of the contract at a specific address.
    function sizeAt(address _addr) internal view returns (uint256 _size) {
        assembly {
            // retrieve the size of the code, this needs assembly
            _size := extcodesize(_addr)
        }
    }

    /// @dev Source from: https://github.com/ethereum/solidity/blob/v0.7.6/docs/assembly.rst#example
    function at(address _addr, uint256 sizeReduction) internal view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := sub(extcodesize(_addr), sizeReduction) 
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}