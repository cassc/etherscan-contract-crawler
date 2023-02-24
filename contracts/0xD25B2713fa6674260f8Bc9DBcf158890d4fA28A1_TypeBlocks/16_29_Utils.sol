// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Utils {
    function join(bytes1[] memory a) internal pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 1, 0);
    }

    function _joinValueType(
        uint256 a,
        uint256 typeLength,
        uint256 shiftLeft
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            let inputLength := mload(a)
            let inputData := add(a, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Initialize the length of the final bytes: length is typeLength x inputLength (array of bytes4)
            mstore(tempBytes, mul(inputLength, typeLength))
            let memoryPointer := add(tempBytes, 0x20)

            // Iterate over all bytes4
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentSlot := shl(shiftLeft, mload(pointer))
                mstore(memoryPointer, currentSlot)
                memoryPointer := add(memoryPointer, typeLength)
            }

            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }

    function isStringExists(string memory value) internal pure returns (bool) {
        if(bytes(value).length>0){
            return true;
        } else {
            return false;
        }
    }

    function getRandom(uint256 input, uint256 max) internal view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(input, address(this)))) % max);
    }

}