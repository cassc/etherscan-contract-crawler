// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "src/RBT.sol";

contract DeprecatedRBT is RBT {
    error InvalidShortString();

    function updateERC20MetaData(
        string memory name,
        string memory symbol
    ) external onlyOwner {
        if (bytes(name).length < 32 && bytes(symbol).length < 32) {
            bytes32 nameBytes32 = _completeShortStringToBytes32(bytes(name));
            bytes32 symbolBytes32 = _completeShortStringToBytes32(
                bytes(symbol)
            );
            assembly {
                sstore(0x36, nameBytes32)
                sstore(0x37, symbolBytes32)
            }
        } else {
            revert InvalidShortString();
        }
    }

    function _completeShortStringToBytes32(
        bytes memory stringBytes
    ) internal pure returns (bytes32) {
        if (stringBytes.length < 32) {
            bytes memory re = new bytes(32);
            for (uint256 i = 0; i < stringBytes.length; i++) {
                re[i] = stringBytes[i];
            }
            re[31] = bytes1(uint8(stringBytes.length * 2));

            return bytes32(abi.encodePacked(re));
        } else {
            revert InvalidShortString();
        }
    }
}