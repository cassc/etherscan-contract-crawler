// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Array Utils
 *
 * @notice Solidity doesn't always work with arrays in an optimal way.
 *      This library collects functions helping to optimize gas usage
 *      when working with arrays in Solidity.
 *
 * @dev One of the most important use cases for arrays is "tight" arrays -
 *      arrays which store values significantly less than 256-bits numbers
 */
library ArrayUtils {
	/**
	 * @dev Pushes `n` 32-bits values sequentially into storage allocated array `data`
	 *      starting from the 32-bits value `v0`
	 *
	 * @dev Optimizations comparing to non-assembly implementation:
	 *      - reads+writes to array size slot only once (instead of `n` times)
	 *      - reads from the array data slots only once (instead of `7n/8` times)
	 *      - writes into array data slots `n/8` times (instead of `n` times)
	 *
	 * @dev Maximum gas saving estimate: ~3n sstore, or 15,000 * n
	 *
	 * @param data storage array pointer to an array of 32-bits elements
	 * @param v0 first number to push into the array
	 * @param n number of values to push, pushes [v0, ..., v0 + n - 1]
	 */
	function push32(uint32[] storage data, uint32 v0, uint32 n) internal {
		// we're going to write 32-bits values into 256-bits storage slots of the array
		// each 256-slot can store up to 8 32-bits sub-blocks, it can also be partially empty
		assembly {
			// for dynamic arrays their slot (array.slot) contains the array length
			// array data is stored separately in consequent storage slots starting
			// from the slot with the address keccak256(array.slot)

			// read the array length into `len` and increase it by `n`
			let len := sload(data.slot)
			sstore(data.slot, add(len, n))

			// find where to write elements and store this location into `loc`
			// load array storage slot number into memory onto position 0,
			// calculate the keccak256 of the slot number (first 32 bytes at position 0)
			// - this will point to the beginning of the array,
			// so we add array length divided by 8 to point to the last array slot
			mstore(0, data.slot)
			let loc := add(keccak256(0, 32), div(len, 8))

			// if we start writing data into already partially occupied slot (`len % 8 != 0`)
			// we need to modify the contents of that slot: read it and rewrite it
			let offset := mod(len, 8)
			if not(iszero(offset)) {
				// how many 32-bits sub-blocks left in the slot
				let left := sub(8, offset)
				// update the `left` value not to exceed `n`
				if gt(left, n) { left := n }
				// load the contents of the first slot (partially occupied)
				let v256 := sload(loc)
				// write the slot in 32-bits sub-blocks
				for { let j := 0 } lt(j, left) { j := add(j, 1) } {
					// write sub-block `j` at offset: `(j + offset) * 32` bits, length: 32-bits
					// v256 |= (v0 + j) << (j + offset) * 32
					v256 := or(v256, shl(mul(add(j, offset), 32), add(v0, j)))
				}
				// write first slot back, it can be still partially occupied, it can also be full
				sstore(loc, v256)
				// update `loc`: move to the next slot
				loc := add(loc, 1)
				// update `v0`: increment by number of values pushed
				v0 := add(v0, left)
				// update `n`: decrement by number of values pushed
				n := sub(n, left)
			}

			// rest of the slots (if any) are empty and will be only written to
			// write the array in 256-bits (8x32) slots
			// `i` iterates [0, n) with the 256-bits step, which is 8 taken `n` is 32-bits long
			for { let i := 0 } lt(i, n) { i := add(i, 8) } {
				// how many 32-bits sub-blocks left in the slot
				let left := 8
				// update the `left` value not to exceed `n`
				if gt(left, n) { left := n }
				// init the 256-bits slot value
				let v256 := 0
				// write the slot in 32-bits sub-blocks
				for { let j := 0 } lt(j, left) { j := add(j, 1) } {
					// write sub-block `j` at offset: `j * 32` bits, length: 32-bits
					// v256 |= (v0 + i + j) << j * 32
					v256 := or(v256, shl(mul(j, 32), add(v0, add(i, j))))
				}
				// write slot `i / 8`
				sstore(add(loc, div(i, 8)), v256)
			}
		}
	}

}