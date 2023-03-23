// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract BLS12381 {
    struct Fp {
        uint256 a;
        uint256 b;
    }

    uint8 constant MOD_EXP_PRECOMPILE_ADDRESS = 0x5;
    string constant BLS_SIG_DST = 'BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_+';

    // Reduce the number encoded as the big-endian slice of data[start:end] modulo the BLS12-381 field modulus.
    // Copying of the base is cribbed from the following:
    // https://github.com/ethereum/solidity-examples/blob/f44fe3b3b4cca94afe9c2a2d5b7840ff0fafb72e/src/unsafe/Memory.sol#L57-L74
    function reduceModulo(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private view returns (bytes memory) {
        uint256 length = end - start;
        assert(length <= data.length);

        bytes memory result = new bytes(48);

        bool success;
        assembly {
            let p := mload(0x40)
        // length of base
            mstore(p, length)
        // length of exponent
            mstore(add(p, 0x20), 0x20)
        // length of modulus
            mstore(add(p, 0x40), 48)
        // base
        // first, copy slice by chunks of EVM words
            let ctr := length
            let src := add(add(data, 0x20), start)
            let dst := add(p, 0x60)
            for {

            } or(gt(ctr, 0x20), eq(ctr, 0x20)) {
                ctr := sub(ctr, 0x20)
            } {
                mstore(dst, mload(src))
                dst := add(dst, 0x20)
                src := add(src, 0x20)
            }
        // next, copy remaining bytes in last partial word
            let mask := sub(exp(256, sub(0x20, ctr)), 1)
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dst), mask)
            mstore(dst, or(destpart, srcpart))
        // exponent
            mstore(add(p, add(0x60, length)), 1)
        // modulus
            let modulusAddr := add(p, add(0x60, add(0x10, length)))
            mstore(
            modulusAddr,
            or(mload(modulusAddr), 0x1a0111ea397fe69a4b1ba7b6434bacd7)
            ) // pt 1
            mstore(
            add(p, add(0x90, length)),
            0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
            ) // pt 2
            success := staticcall(
            sub(gas(), 2000),
            MOD_EXP_PRECOMPILE_ADDRESS,
            p,
            add(0xB0, length),
            add(result, 0x20),
            48
            )
        // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'call to modular exponentiation precompile failed');
        return result;
    }

    function sliceToUint(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private pure returns (uint256 result) {
        uint256 length = end - start;
        assert(length <= 32);

        for (uint256 i; i < length; ) {
            bytes1 b = data[start + i];
            result = result + (uint8(b) * 2**(8 * (length - i - 1)));
        unchecked {
            ++i;
        }
        }
    }

    function convertSliceToFp(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private view returns (Fp memory) {
        bytes memory fieldElement = reduceModulo(data, start, end);
        uint256 a = sliceToUint(fieldElement, 0, 16);
        uint256 b = sliceToUint(fieldElement, 16, 48);
        return Fp(a, b);
    }

    function expandMessage(bytes32 message) private pure returns (bytes memory) {
        bytes memory b0Input = new bytes(143);
        for (uint256 i; i < 32; ) {
            b0Input[i + 64] = message[i];
        unchecked {
            ++i;
        }
        }
        b0Input[96] = 0x01;
        for (uint256 i; i < 44; ) {
            b0Input[i + 99] = bytes(BLS_SIG_DST)[i];
        unchecked {
            ++i;
        }
        }

        bytes32 b0 = sha256(abi.encodePacked(b0Input));

        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(
            abi.encodePacked(b0, bytes1(0x01), bytes(BLS_SIG_DST))
        );
        assembly {
            mstore(add(output, 0x20), chunk)
        }

        for (uint256 i = 2; i < 9; ) {
            bytes32 input;
            assembly {
                input := xor(b0, mload(add(output, add(0x20, mul(0x20, sub(i, 2))))))
            }
            chunk = sha256(
                abi.encodePacked(input, bytes1(uint8(i)), bytes(BLS_SIG_DST))
            );
            assembly {
                mstore(add(output, add(0x20, mul(0x20, sub(i, 1)))), chunk)
            }
        unchecked {
            ++i;
        }
        }

        return output;
    }

    function FpToArray55_7(Fp memory fp) private pure returns (uint256[7] memory) {
        uint256[7] memory result;
        uint256 mask = ((1 << 55) - 1);
        result[0] = (fp.b & (mask << (55 * 0))) >> (55 * 0);
        result[1] = (fp.b & (mask << (55 * 1))) >> (55 * 1);
        result[2] = (fp.b & (mask << (55 * 2))) >> (55 * 2);
        result[3] = (fp.b & (mask << (55 * 3))) >> (55 * 3);
        result[4] = (fp.b & (mask << (55 * 4))) >> (55 * 4);
        uint256 newMask = (1 << 19) - 1;
        result[4] = result[4] | ((fp.a & newMask) << 36);
        result[5] = (fp.a & (mask << 19)) >> 19;
        result[6] = (fp.a & (mask << (55 + 19))) >> (55 + 19);

        return result;
    }

    function hashToField(bytes32 message)
    internal
    view
    returns (uint256[28] memory input)
    {
        bytes memory some_bytes = expandMessage(message);
        uint256[7][2][2] memory result;
        result[0][0] = FpToArray55_7(convertSliceToFp(some_bytes, 0, 64));
        result[0][1] = FpToArray55_7(convertSliceToFp(some_bytes, 64, 128));
        result[1][0] = FpToArray55_7(convertSliceToFp(some_bytes, 128, 192));
        result[1][1] = FpToArray55_7(convertSliceToFp(some_bytes, 192, 256));
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2; j++) {
                for (uint256 k = 0; k < 7; k++) {
                    input[i * 14 + j * 7 + k] = result[i][j][k];
                }
            }
        }
        return input;
    }
}