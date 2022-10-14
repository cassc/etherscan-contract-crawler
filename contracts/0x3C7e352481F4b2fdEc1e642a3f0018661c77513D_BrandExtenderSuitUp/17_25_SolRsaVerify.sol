// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

library SolRsaVerify {

    bytes19 constant sha256Prefix = 0x3031300d060960864801650304020105000420;

    function memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        if (_len > 0) {
            uint256 mask = 256**(32 - _len) - 1;
            assembly {
                let srcpart := and(mload(_src), not(mask))
                let destpart := and(mload(_dest), mask)
                mstore(_dest, or(destpart, srcpart))
            }
        }
    }

    function join(
        bytes memory _s,
        bytes memory _e,
        bytes memory _m
    ) internal pure returns (bytes memory) {
        uint256 slen = _s.length;
        uint256 elen = _e.length;
        uint256 mlen = _m.length;
        uint256 sptr;
        uint256 eptr;
        uint256 mptr;
        uint256 inputPtr;

        bytes memory input = new bytes(0x60 + slen + elen + mlen);
        assembly {
            sptr := add(_s, 0x20)
            eptr := add(_e, 0x20)
            mptr := add(_m, 0x20)
            mstore(add(input, 0x20), slen)
            mstore(add(input, 0x40), elen)
            mstore(add(input, 0x60), mlen)
            inputPtr := add(input, 0x20)
        }

        memcpy(inputPtr + 0x60, sptr, slen);
        memcpy(inputPtr + 0x60 + slen, eptr, elen);
        memcpy(inputPtr + 0x60 + slen + elen, mptr, mlen);

        return input;
    }

    function sliceUint(bytes memory bs, uint start)
    internal pure
    returns (uint)
    {
        require(bs.length >= start + 32, "slicing out of range");
        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    /** @dev Verifies a PKCSv1.5 SHA256 signature
     * @param _sha256 is the sha256 of the data
     * @param _s is the signature
     * @param _e is the exponent
     * @param _m is the modulus
     * @return 0 if success, >0 otherwise
     */
    function pkcs1Sha256Verify(
        bytes32 _sha256,
        bytes memory _s,
        bytes memory _e,
        bytes memory _m
    ) internal view returns (uint256) {
        uint256 decipherlen = _m.length;
        require(decipherlen >= 62); // _m.length >= sha256Prefix.length + _sha256.length + 11 = 19 + 32 + 11 = 62
        // decipher
        bytes memory input = join(_s, _e, _m);  //
        // return 0;
        uint256 inputlen  = input.length;

        bytes memory decipher = new bytes(decipherlen);

        // cp0;

        assembly {
            pop(staticcall(sub(gas(), 2000), 0x05, add(input, 0x20), inputlen, add(decipher, 0x20), decipherlen))
        }

        // optimized for 1024 bytes
        if (
            sliceUint(decipher, 0 )    != 0x0001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            || uint(sliceUint(decipher, 13))    != 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 
            || uint(sliceUint(decipher, 13+32)) != 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00 
            
            ) {
            return 1;
        }

        // or uncomment for other than 1024 (start)
        // if (uint8(decipher[0]) != 0 || uint8(decipher[1]) != 1) {
        //     return 1;
        // }

        // uint256 i;
        
        // for (i = 2; i < decipherlen - 52; i++) {
        //     if (decipher[i] != 0xff) {
        //         return 2;
        //     }
        // }

        // if (decipher[decipherlen - 52] != 0) {
        //     return 3;
        // }
        // or uncomment for other than 1024 (end)

        if (uint(bytes32(sha256Prefix)) != sliceUint(decipher, decipherlen - 51) & 0xffffffffffffffffffffffffffffffffffffff00000000000000000000000000){
            return 4;
        }

        if (uint256(_sha256) != sliceUint(decipher,decipherlen - 32)){
            return 5;
        }
        return 0;
    }

    /** @dev Verifies a PKCSv1.5 SHA256 signature
     * @param _data to verify
     * @param _s is the signature
     * @param _e is the exponent
     * @param _m is the modulus
     * @return 0 if success, >0 otherwise
     */
    function pkcs1Sha256VerifyRaw(
        bytes memory _data,
        bytes memory _s,
        bytes memory _e,
        bytes memory _m
    ) internal view returns (uint256) {
        return pkcs1Sha256Verify(sha256(_data), _s, _e, _m);
    }
}