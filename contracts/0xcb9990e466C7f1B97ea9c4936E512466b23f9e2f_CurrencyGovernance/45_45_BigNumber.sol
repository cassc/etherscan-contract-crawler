pragma solidity ^0.8.0;

/*
MIT License

Copyright (c) 2017 zcoinofficial

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Originated from https://github.com/zcoinofficial/solidity-BigNumber

// SPDX-License-Identifier: MIT

// solhint-disable no-inline-assembly, no-empty-blocks, function-max-lines

/**
 * @title Big integer math library
 */
library BigNumber {
    /*
     * BigNumber is defined as a struct named 'Instance' to avoid naming conflicts.
     * DO NOT ALLOW INSTANTIATING THIS DIRECTLY - use the 'from' functions defined below.
     * Hoping in future Solidity will allow visibility modifiers on structs.
     */

    // @notice store bytes in word-size (32 byte) chunks
    struct Instance {
        bytes32[] value;
    }

    /**
     * @notice Create a new Bignumber instance from byte array
     * @dev    If the caller subsequently clears or modifies the input _value, it will corrupt the BigNumber value.
     * @param _value Number stored in big endian bytes
     * @return instance of BigNumber
     */
    function from(bytes memory _value) internal view returns (Instance memory) {
        uint256 length = _value.length;
        if (length == 0) {
            // Zero
            return Instance(new bytes32[](0));
        }
        uint256 numSlots = (length + 31) >> 5;
        Instance memory _instance = Instance(new bytes32[](numSlots));

        // ensure there aren't any leading zero words
        // this is not the zeroOffset yet, this is the modulo of the length
        uint256 zeroOffset = length & 0x1f;
        bytes32 word;
        if (zeroOffset == 0) {
            assembly {
                // load the first word from _value
                word := mload(add(_value, 0x20))
            }
            require(
                word != 0,
                "High-word must be set when input is bytes32-aligned"
            );
        } else {
            // calculate zeroOffset
            zeroOffset = 32 - zeroOffset;
            assembly {
                // load the first word from _value
                word := shr(mul(0x8, zeroOffset), mload(add(_value, 0x20)))
            }
            require(
                word != 0,
                "High-word must be set when input is bytes32-aligned"
            );
        }

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so we just load the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional 32 - offset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, numSlots)),
                    0x04,
                    add(_value, 0x20),
                    length,
                    add(mload(_instance), add(0x20, zeroOffset)),
                    length
                )
            ) {
                revert(0, 0)
            }
        }

        return _instance;
    }

    /**
     * @notice Create a new BigNumber instance from uint256
     * @param _value Number stored in uint256
     * @return instance of BigNumber
     */
    function from(uint256 _value)
        internal
        pure
        returns (Instance memory instance)
    {
        if (_value != 0x0) {
            instance = Instance(new bytes32[](1));
            instance.value[0] = bytes32(_value);
        }
    }

    /**
     * @notice Convert instance to padded byte array
     * @param _instance BigNumber instance to convert
     * @param _size Desired size of byte array
     * @return result byte array
     */
    function asBytes(Instance memory _instance, uint256 _size)
        internal
        view
        returns (bytes memory)
    {
        uint256 length = _instance.value.length;
        require(_size & 0x1f == 0x0, "Size must be multiple of 0x20");

        uint256 _byteLength = length << 5;
        require(_size >= _byteLength, "Number too large to represent");

        uint256 zeroOffset = _size - _byteLength;
        bytes memory result = new bytes(_size);

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so we just load the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional zeroOffset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, length)),
                    0x04,
                    add(mload(_instance), 0x20),
                    _byteLength,
                    add(result, add(0x20, zeroOffset)),
                    _byteLength
                )
            ) {
                revert(0, 0)
            }
        }

        return result;
    }

    /**
     * @notice Convert instance to minimal byte array
     * @param _instance BigNumber instance to convert
     * @return result byte array
     */
    function asBytes(Instance memory _instance)
        internal
        view
        returns (bytes memory)
    {
        uint256 _length = _instance.value.length;
        if (_length == 0) {
            return new bytes(0);
        }

        bytes32 firstWord = _instance.value[0];
        uint256 zeroOffset = 0;
        if (firstWord >> 128 == 0) {
            firstWord <<= 128;
            zeroOffset += 16;
        }
        if (firstWord >> 192 == 0) {
            firstWord <<= 64;
            zeroOffset += 8;
        }
        if (firstWord >> 224 == 0) {
            firstWord <<= 32;
            zeroOffset += 4;
        }
        if (firstWord >> 240 == 0) {
            firstWord <<= 16;
            zeroOffset += 2;
        }
        if (firstWord >> 248 == 0) {
            zeroOffset += 1;
        }

        uint256 _byteLength = (_length << 5) - zeroOffset;

        bytes memory result = new bytes(_byteLength);

        assembly {
            /*
            Call precompiled contract to copy data
            gas cost is 15 + 3/word
            there is no packing for structs in memory, so we just load the slot for _instance
            shift 32 bytes to skip the length value of each reference type
            shift an additional 32 + zeroOffset bits on the result to naturally create the offset
            */
            if iszero(
                staticcall(
                    add(0x0f, mul(0x03, _length)),
                    0x04,
                    add(mload(_instance), add(0x20, zeroOffset)),
                    _byteLength,
                    add(result, 0x20),
                    _byteLength
                )
            ) {
                revert(0, 0)
            }
        }

        return result;
    }

    /**
     * @notice Obtain length (in bytes) of BigNumber instance
     * This will be rounded up to nearest multiple of 0x20 bytes
     *
     * @param _instance BigNumber instance
     * @return Size (in bytes) of BigNumber instance
     */
    function byteLength(Instance memory _instance)
        internal
        pure
        returns (uint256)
    {
        return _instance.value.length << 5;
    }

    /**
     * @notice Obtain minimal length (in bytes) of BigNumber instance
     *
     * @param _instance BigNumber instance
     * @return Size (in bytes) of minimal BigNumber instance
     */
    function minimalByteLength(Instance memory _instance)
        internal
        pure
        returns (uint256)
    {
        uint256 _byteLength = byteLength(_instance);

        if (_byteLength == 0) {
            return 0;
        }

        bytes32 firstWord = _instance.value[0];
        uint256 zeroOffset = 0;
        if (firstWord >> 128 == 0) {
            firstWord <<= 128;
            zeroOffset += 16;
        }
        if (firstWord >> 192 == 0) {
            firstWord <<= 64;
            zeroOffset += 8;
        }
        if (firstWord >> 224 == 0) {
            firstWord <<= 32;
            zeroOffset += 4;
        }
        if (firstWord >> 240 == 0) {
            firstWord <<= 16;
            zeroOffset += 2;
        }
        if (firstWord >> 248 == 0) {
            zeroOffset += 1;
        }

        return _byteLength - zeroOffset;
    }

    /**
     * @notice Perform modular exponentiation of BigNumber instance
     * @param _base Base number
     * @param _exponent Exponent
     * @param _modulus Modulus
     * @return result (_base ^ _exponent) % _modulus
     */
    function modexp(
        Instance memory _base,
        Instance memory _exponent,
        Instance memory _modulus
    ) internal view returns (Instance memory result) {
        result.value = innerModExp(
            _base.value,
            _exponent.value,
            _modulus.value
        );
    }

    /**
     * @notice Perform modular multiplication of BigNumber instances
     * @param _a number
     * @param _b number
     * @param _modulus Modulus
     * @return (_a * _b) % _modulus
     */
    function modmul(
        Instance memory _a,
        Instance memory _b,
        Instance memory _modulus
    ) internal view returns (Instance memory) {
        return modulo(multiply(_a, _b), _modulus);
    }

    /**
     * @notice Compare two BigNumber instances for equality
     * @param _a number
     * @param _b number
     * @return -1 if (_a<_b), 1 if (_a>_b) and 0 if (_a==_b)
     */
    function cmp(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (int256)
    {
        uint256 aLength = _a.value.length;
        uint256 bLength = _b.value.length;
        if (aLength > bLength) return 0x1;
        if (bLength > aLength) return -0x1;

        bytes32 aWord;
        bytes32 bWord;

        for (uint256 i = 0; i < _a.value.length; i++) {
            aWord = _a.value[i];
            bWord = _b.value[i];

            if (aWord > bWord) {
                return 1;
            }
            if (bWord > aWord) {
                return -1;
            }
        }

        return 0;
    }

    /**
     * @notice Add two BigNumber instances
     * Not used outside the library itself
     */
    function privateAdd(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (Instance memory instance)
    {
        uint256 aLength = _a.value.length;
        uint256 bLength = _b.value.length;
        if (aLength == 0) return _b;
        if (bLength == 0) return _a;

        if (aLength >= bLength) {
            instance.value = innerAdd(_a.value, _b.value);
        } else {
            instance.value = innerAdd(_b.value, _a.value);
        }
    }

    /**
     * @dev max + min
     */
    function innerAdd(bytes32[] memory _max, bytes32[] memory _min)
        private
        pure
        returns (bytes32[] memory result)
    {
        assembly {
            // Get the highest available block of memory
            let result_start := mload(0x40)

            // uint256 max (all bits set; inverse of 0)
            let uint_max := not(0x0)

            let carry := 0x0

            // load lengths of inputs
            let max_len := shl(5, mload(_max))
            let min_len := shl(5, mload(_min))

            // point to last word of each byte array.
            let max_ptr := add(_max, max_len)
            let min_ptr := add(_min, min_len)

            // set result_ptr end.
            let result_ptr := add(add(result_start, 0x20), max_len)

            // while 'min' words are still available
            // for(int i=0; i<min_length; i+=0x20)
            for {
                let i := 0x0
            } lt(i, min_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)
                // get next word for 'min'
                let min_val := mload(min_ptr)

                // check if we need to carry over to a new word
                // sum of both words that we're adding
                let min_max := add(min_val, max_val)
                // plus the carry amount if there is one
                let min_max_carry := add(min_max, carry)
                // store result
                mstore(result_ptr, min_max_carry)
                // carry again if we've overflowed
                carry := or(lt(min_max, min_val), lt(min_max_carry, carry))
                // point to next 'min' word
                min_ptr := sub(min_ptr, 0x20)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // remainder after 'min' words are complete.
            // for(int i=min_length; i<max_length; i+=0x20)
            for {
                let i := min_len
            } lt(i, max_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)

                // result_word = max_word+carry
                let max_carry := add(max_val, carry)
                mstore(result_ptr, max_carry)
                // finds whether or not to set the carry bit for the next iteration.
                carry := lt(max_carry, carry)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // store the carry bit
            mstore(result_ptr, carry)
            // move result ptr up by a slot if no carry
            result := add(result_start, sub(0x20, shl(0x5, carry)))

            // store length of result. we are finished with the byte array.
            mstore(result, add(shr(5, max_len), carry))

            // Update freemem pointer to point to new end of memory.
            mstore(0x40, add(result, add(shl(5, mload(result)), 0x20)))
        }
    }

    /**
     * @notice Return absolute difference between two instances
     * Not used outside the library itself
     */
    function absdiff(Instance memory _a, Instance memory _b)
        internal
        pure
        returns (Instance memory instance)
    {
        int256 compare = cmp(_a, _b);

        if (compare == 1) {
            instance.value = innerDiff(_a.value, _b.value);
        } else if (compare == -0x1) {
            instance.value = innerDiff(_b.value, _a.value);
        }
    }

    /**
     * @dev max - min
     */
    function innerDiff(bytes32[] memory _max, bytes32[] memory _min)
        private
        pure
        returns (bytes32[] memory result)
    {
        uint256 carry = 0x0;
        assembly {
            // Get the highest available block of memory
            let result_start := mload(0x40)

            // uint256 max. (all bits set; inverse of 0)
            let uint_max := not(0x0)

            // load lengths of inputs
            let max_len := shl(5, mload(_max))
            let min_len := shl(5, mload(_min))

            //go to end of arrays
            let max_ptr := add(_max, max_len)
            let min_ptr := add(_min, min_len)

            //point to least significant result word.
            let result_ptr := add(result_start, max_len)
            // save memory_end to update free memory pointer at the end.
            let memory_end := add(result_ptr, 0x20)

            // while 'min' words are still available.
            // for(int i=0; i<min_len; i+=0x20)
            for {
                let i := 0x0
            } lt(i, min_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)
                // get next word for 'min'
                let min_val := mload(min_ptr)

                // result_word = (max_word-min_word)-carry
                // find whether or not to set the carry bit for the next iteration.
                let max_min := sub(max_val, min_val)
                let max_min_carry := sub(max_min, carry)
                mstore(result_ptr, max_min_carry)
                carry := or(gt(max_min, max_val), gt(max_min_carry, max_min))

                // point to next 'result' word
                min_ptr := sub(min_ptr, 0x20)
                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // remainder after 'min' words are complete.
            // for(int i=min_len; i<max_len; i+=0x20)
            for {
                let i := min_len
            } lt(i, max_len) {
                i := add(i, 0x20)
            } {
                // get next word for 'max'
                let max_val := mload(max_ptr)

                // result_word = max_word-carry
                let max_carry := sub(max_val, carry)
                mstore(result_ptr, max_carry)
                carry := gt(max_carry, max_val)

                // point to next 'result' word
                result_ptr := sub(result_ptr, 0x20)
                // point to next 'max' word
                max_ptr := sub(max_ptr, 0x20)
            }

            // the following code removes any leading words containing all zeroes in the result.
            let shift := 0x20
            for {

            } iszero(mload(add(result_ptr, shift))) {

            } {
                shift := add(shift, 0x20)
            }

            shift := sub(shift, 0x20)
            if gt(shift, 0x0) {
                // for(result_ptr+=0x20;; result==0x0; result_ptr+=0x20)
                // push up the start pointer for the result..
                result_start := add(result_start, shift)
                // and subtract a word (0x20 bytes) from the result length.
                max_len := sub(max_len, shift)
            }

            // point 'result' bytes value to the correct address in memory
            result := result_start

            // store length of result. we are finished with the byte array.
            mstore(result, shr(5, max_len))

            // Update freemem pointer.
            mstore(0x40, memory_end)
        }

        return (result);
    }

    /**
     * @notice Multiply two instances
     * @param _a number
     * @param _b number
     * @return res _a * _b
     */
    function multiply(Instance memory _a, Instance memory _b)
        internal
        view
        returns (Instance memory res)
    {
        res = opAndSquare(_a, _b, true);

        if (cmp(_a, _b) != 0x0) {
            // diffSquared = (a-b)^2
            Instance memory diffSquared = opAndSquare(_a, _b, false);

            // res = add_and_square - diffSquared
            // diffSquared can never be greater than res
            // so we are safe to use innerDiff directly instead of absdiff
            res.value = innerDiff(res.value, diffSquared.value);
        }
        res = privateRightShift(res);
        return res;
    }

    /**
     * @dev take two instances, add or diff them, then square the result
     */
    function opAndSquare(
        Instance memory _a,
        Instance memory _b,
        bool _add
    ) private view returns (Instance memory res) {
        Instance memory two = from(0x2);

        bytes memory _modulus;

        res = _add ? privateAdd(_a, _b) : absdiff(_a, _b);
        uint256 modIndex = (res.value.length << 6) + 0x1;

        _modulus = new bytes(1);
        assembly {
            //store length of modulus
            mstore(_modulus, modIndex)
            //set first modulus word
            mstore(
                add(_modulus, 0x20),
                0xf000000000000000000000000000000000000000000000000000000000000000
            )
            //update freemem pointer to be modulus index + length
            // mstore(0x40, add(_modulus, add(modIndex, 0x20)))
        }

        Instance memory modulus;
        modulus = from(_modulus);

        res = modexp(res, two, modulus);
    }

    /**
     * @dev a % mod
     */
    function modulo(Instance memory _a, Instance memory _mod)
        private
        view
        returns (Instance memory res)
    {
        Instance memory one = from(1);
        res = modexp(_a, one, _mod);
    }

    /**
     * @dev Use the precompile to perform _base ^ _exp % _mod
     */
    function innerModExp(
        bytes32[] memory _base,
        bytes32[] memory _exp,
        bytes32[] memory _mod
    ) private view returns (bytes32[] memory ret) {
        assembly {
            let bl := shl(5, mload(_base))
            let el := shl(5, mload(_exp))
            let ml := shl(5, mload(_mod))

            // Free memory pointer is always stored at 0x40
            let freemem := mload(0x40)

            // arg[0] = base.length @ +0
            mstore(freemem, bl)

            // arg[1] = exp.length @ + 0x20
            mstore(add(freemem, 0x20), el)

            // arg[2] = mod.length @ + 0x40
            mstore(add(freemem, 0x40), ml)

            // arg[3] = base.bits @ + 0x60
            // Use identity built-in (contract 0x4) as a cheap memcpy
            let success := staticcall(
                450,
                0x4,
                add(_base, 0x20),
                bl,
                add(freemem, 0x60),
                bl
            )

            // arg[4] = exp.bits @ +0x60+base.length
            let argBufferSize := add(0x60, bl)
            success := and(
                success,
                staticcall(
                    450,
                    0x4,
                    add(_exp, 0x20),
                    el,
                    add(freemem, argBufferSize),
                    el
                )
            )

            // arg[5] = mod.bits @ +0x60+base.length+exp.length
            argBufferSize := add(argBufferSize, el)
            success := and(
                success,
                staticcall(
                    0x1C2,
                    0x4,
                    add(_mod, 0x20),
                    ml,
                    add(freemem, argBufferSize),
                    ml
                )
            )

            // Total argBufferSize of input = 0x60+base.length+exp.length+mod.length
            argBufferSize := add(argBufferSize, ml)
            // Invoke contract 0x5, put return value right after mod.length, @ +0x60
            success := and(
                success,
                staticcall(
                    sub(gas(), 0x546),
                    0x5,
                    freemem,
                    argBufferSize,
                    add(0x60, freemem),
                    ml
                )
            )

            if iszero(success) {
                revert(0x0, 0x0)
            } //fail where we haven't enough gas to make the call

            let length := ml
            let result_ptr := add(0x60, freemem)

            // the following code removes any leading words containing all zeroes in the result.
            let shift := 0x0
            for {

            } and(gt(length, shift), iszero(mload(add(result_ptr, shift)))) {

            } {
                shift := add(shift, 0x20)
            }

            if gt(shift, 0x0) {
                // push up the start pointer for the result..
                result_ptr := add(result_ptr, shift)
                // and subtract a the words from the result length.
                length := sub(length, shift)
            }

            ret := sub(result_ptr, 0x20)
            mstore(ret, shr(5, length))

            // point to the location of the return value (length, bits)
            // assuming mod length is multiple of 0x20, return value is already in the right format.
            // Otherwise, the offset needs to be adjusted.
            // ret := add(0x40,freemem)
            // deallocate freemem pointer
            mstore(0x40, add(add(0x60, freemem), ml))
        }
        return ret;
    }

    /**
     * @dev Right shift instance 'dividend' by 'value' bits.
     * This clobbers the passed _dividend
     */
    function privateRightShift(Instance memory _dividend)
        internal
        pure
        returns (Instance memory)
    {
        bytes32[] memory result;
        uint256 wordShifted;
        uint256 maskShift = 0xfe;
        uint256 precedingWord;
        uint256 resultPtr;
        uint256 length = _dividend.value.length << 5;

        require(length <= 1024, "Length must be less than 8192 bits");

        assembly {
            resultPtr := add(mload(_dividend), length)
        }

        for (int256 i = int256(length) - 0x20; i >= 0x0; i -= 0x20) {
            // for each word:
            assembly {
                // get next word
                wordShifted := mload(resultPtr)
                // if i==0x0:
                switch iszero(i)
                case 0x1 {
                    // handles msword: no precedingWord needed.
                    precedingWord := 0x0
                }
                default {
                    // else get precedingWord.
                    precedingWord := mload(sub(resultPtr, 0x20))
                }
            }
            // right shift current by value
            wordShifted >>= 0x2;
            // left shift next significant word by maskShift
            precedingWord <<= maskShift;
            assembly {
                // store OR'd precedingWord and shifted value in-place
                mstore(resultPtr, or(wordShifted, precedingWord))
            }
            // point to next value.
            resultPtr -= 0x20;
        }

        assembly {
            // the following code removes a leading word if any containing all zeroes in the result.
            resultPtr := add(resultPtr, 0x20)

            if and(gt(length, 0x0), iszero(mload(resultPtr))) {
                // push up the start pointer for the result..
                resultPtr := add(resultPtr, 0x20)
                // and subtract a word (0x20 bytes) from the result length.
                length := sub(length, 0x20)
            }

            result := sub(resultPtr, 0x20)
            mstore(result, shr(5, length))
        }

        return Instance(result);
    }
}