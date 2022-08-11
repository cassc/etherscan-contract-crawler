//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// author: phaze

// assumption: n << m
// caveats: splits random number into 16 parts for efficiency
// this means that 65536 is the highest random number
// (can skew uniform distributions when m is hight)
library choice {
    function selectNOfM(
        uint256 n,
        uint256 m,
        uint256 r
    ) internal pure returns (uint256[] memory selected) {
        if (n > m) n = m;

        selected = new uint256[](n);

        uint256 s;
        uint256 slot;

        uint256 j;
        uint256 c;

        bool invalidChoice;

        unchecked {
            for (uint256 i; i < n; ++i) {
                do {
                    slot = (s & 0xF) << 4;
                    if (slot == 0 && i != 0) r = uint256(keccak256(abi.encode(r, s)));
                    c = ((r >> slot) & 0xFFFF) % m;
                    invalidChoice = false;
                    for (j = 0; j < i && !invalidChoice; ++j) invalidChoice = selected[j] == c;
                    ++s;
                } while (invalidChoice);

                selected[i] = c;
            }
        }
    }
}