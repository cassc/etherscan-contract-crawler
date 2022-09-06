// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Random {
    function inRange(
        uint256 min,
        uint256 max,
        uint256 seed
    ) internal view returns (uint256) {
        return (_generate(seed) % (max - min + 1)) + min; // [min..max]
    }

    function weighted(
        uint256 pool,
        uint256 count,
        uint256 seed
    ) internal view returns (uint256) {
        uint256 last = count - 1;
        uint256 r = _generate(seed) % 100_00; // [0..99_99]
        uint256 w;

        for (uint256 i; i < last; i++) {
            w += uint16(pool >> ((last - i) << 4));

            if (r < w) {
                return i;
            }
        }

        return last;
    }

    function _generate(uint256 seed) private view returns (uint256) {
        unchecked {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.basefee,
                            seed,
                            block.coinbase,
                            uint256(blockhash(block.number - uint8(seed >> (seed & 0x7f)))),
                            // solhint-disable-next-line not-rely-on-time
                            block.timestamp
                        )
                    )
                );
        }
    }
}