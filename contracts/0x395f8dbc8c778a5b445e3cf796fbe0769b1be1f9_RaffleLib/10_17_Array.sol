// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library Array {
    /// @notice Compress `data` to [Length]:{[BytesLength][val...]}
    /// eg. [0, 255, 256] will be convert to bytes series: 0x03 0x00 0x01 0xFF 0x02 0x00 0x01
    /// 0x03 means there are 3 numbers
    /// 0x00 means first number is 0
    /// 0x01 means next number(255) has 1 byte to store the real value
    /// 0xFF equals 255
    /// 256 need 2 bytes(0x02) to store, and its value represented in hex is 0x0100
    function encodeUints(uint256[] memory data) internal pure returns (bytes memory res) {
        uint256 dataLen = data.length;

        require(dataLen <= type(uint8).max);

        unchecked {
            uint256 totalBytes;
            for (uint256 i; i < dataLen; ++i) {
                uint256 val = data[i];
                while (val > 0) {
                    val >>= 8;
                    ++totalBytes;
                }
            }

            res = new bytes(dataLen + totalBytes + 1);
            assembly {
                /// skip res's length, store data length
                mstore8(add(res, 0x20), dataLen)
            }

            /// start from the second element idx
            uint256 resIdx = 0x21;
            for (uint256 i; i < dataLen; ++i) {
                uint256 val = data[i];

                uint256 byteLen;
                while (val > 0) {
                    val >>= 8;
                    ++byteLen;
                }

                assembly {
                    /// store bytes length of the `i`th element
                    mstore8(add(res, resIdx), byteLen)
                }
                ++resIdx;

                val = data[i];
                for (uint256 j; j < byteLen; ++j) {
                    assembly {
                        mstore8(add(res, resIdx), val)
                    }
                    val >>= 8;
                    ++resIdx;
                }
            }
        }
    }

    function decodeUints(bytes memory data) internal pure returns (uint256[] memory res) {
        uint256 dataLen = data.length;
        require(dataLen > 0);

        res = new uint256[](uint8(data[0]));
        uint256 k;

        unchecked {
            for (uint256 i = 1; i < dataLen; ++i) {
                uint256 byteLen = uint8(data[i]);
                /// if byteLen is zero, it means current element is zero, no need to update `res`, just increment `k`
                if (byteLen > 0) {
                    uint256 tmp;
                    /// combine next `byteLen` bytes to `tmp`
                    for (uint256 j; j < byteLen; ++j) {
                        /// skip `byteLen`
                        ++i;

                        tmp |= ((uint256(uint8(data[i]))) << (j * 8));
                    }
                    res[k] = tmp;
                }

                ++k;
            }
        }
    }
}