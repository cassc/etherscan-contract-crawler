// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @title Probable prime tester with Miller-Rabin
 */
contract IsPrime {
    /* Compute modular exponentiation using the modexp precompile contract
     * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
     */
    function expmod(
        uint256 _x,
        uint256 _e,
        uint256 _n
    ) private view returns (uint256 r) {
        assembly {
            let p := mload(0x40) // Load free memory pointer
            mstore(p, 0x20) // Store length of x (256 bit)
            mstore(add(p, 0x20), 0x20) // Store length of e (256 bit)
            mstore(add(p, 0x40), 0x20) // Store length of N (256 bit)
            mstore(add(p, 0x60), _x) // Store x
            mstore(add(p, 0x80), _e) // Store e
            mstore(add(p, 0xa0), _n) // Store n

            // Call precompiled modexp contract, input and output at p
            if iszero(staticcall(gas(), 0x05, p, 0xc0, p, 0x20)) {
                // revert if failed
                revert(0, 0)
            }
            // Load output (256 bit)
            r := mload(p)
        }
    }

    /** @notice Test if number is probable prime
     * Probability of false positive is (1/4)**_k
     * @param _n Number to be tested for primality
     * @param _k Number of iterations
     */
    function isProbablePrime(uint256 _n, uint256 _k)
        public
        view
        returns (bool)
    {
        if (_n == 2 || _n == 3 || _n == 5) {
            return true;
        }
        if (_n == 1 || (_n & 1 == 0)) {
            return false;
        }

        uint256 s = 0;
        uint256 _n3 = _n - 3;
        uint256 _n1 = _n - 1;
        uint256 d = _n1;

        //calculate the trailing zeros on the binary representation of the number
        if (d << 128 == 0) {
            d >>= 128;
            s += 128;
        }
        if (d << 192 == 0) {
            d >>= 64;
            s += 64;
        }
        if (d << 224 == 0) {
            d >>= 32;
            s += 32;
        }
        if (d << 240 == 0) {
            d >>= 16;
            s += 16;
        }
        if (d << 248 == 0) {
            d >>= 8;
            s += 8;
        }
        if (d << 252 == 0) {
            d >>= 4;
            s += 4;
        }
        if (d << 254 == 0) {
            d >>= 2;
            s += 2;
        }
        if (d << 255 == 0) {
            d >>= 1;
            s += 1;
        }

        bytes32 prevBlockHash = blockhash(block.number - 1);

        for (uint256 i = 0; i < _k; ++i) {
            bytes32 hash = keccak256(abi.encode(prevBlockHash, i));
            uint256 a = (uint256(hash) % _n3) + 2;
            uint256 x = expmod(a, d, _n);
            if (x != 1 && x != _n1) {
                uint256 j;
                for (j = 0; j < s; ++j) {
                    x = mulmod(x, x, _n);
                    if (x == _n1) {
                        break;
                    }
                }
                if (j == s) {
                    return false;
                }
            }
        }

        return true;
    }
}