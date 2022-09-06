//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./BytesUtil.sol";

library NameEncoder {
    using BytesUtils for bytes;

    function dnsEncodeName(string memory name)
        internal
        pure
        returns (bytes32 node)
    {
        uint8 labelLength = 0;
        bytes memory bytesName = bytes(name);
        uint256 length = bytesName.length;
        node = 0;
        if (length == 0) {
            return (node);
        }

        // use unchecked to save gas since we check for an underflow
        // and we check for the length before the loop
        unchecked {
            for (uint256 i = length - 1; i >= 0; i--) {
                if (bytesName[i] == ".") {
                    node = keccak256(
                        abi.encodePacked(
                            node,
                            bytesName.keccak(i + 1, labelLength)
                        )
                    );
                    labelLength = 0;
                } else {
                    labelLength += 1;
                }
                if (i == 0) {
                    break;
                }
            }
        }

        node = keccak256(
            abi.encodePacked(node, bytesName.keccak(0, labelLength))
        );
        return (node);
    }
}