// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ArtistBingo} from "./ArtistBingo.sol";

/// @dev a fixed version of getActs that allows overflow in finding in-range act ids
contract ArtistBingoActParser {
    ArtistBingo immutable $bingo;

    constructor(ArtistBingo bingo) {
        $bingo = bingo;
    }

    function getActsForCardId(uint256 id) public view returns (uint8[] memory) {
        return getActs($bingo.cards(id), $bingo.TOTAL_ACTS());
    }

    function getActs(
        uint256 squares,
        uint8 totalActs
    ) public pure returns (uint8[] memory) {
        uint256 used; // bitmap that tracks whether a specific number has been seen
        uint8 counter;
        uint8 seed;
        uint8 act;

        uint8[] memory acts = new uint8[](24);

        for (uint256 i = 0; i < 24; i++) {
            // get byte `seed` from word `squares`
            seed = uint8(squares >> (8 * (31 - i)));

            // reset counter for loop
            counter = 0;

            // determine next non-duplicate act
            while (true) {
                // derive an act
                /// @dev allow overflow via unchecked {}
                unchecked {
                    act = (seed + counter) % totalActs;
                }

                // if the act has not been seen, break
                if ((used & (1 << act)) == 0) break;

                // otherwise, increment counter and loop
                counter++;
            }

            // an act has been found

            // mark act as seen
            used |= (1 << act);

            // include in acts
            acts[i] = act;
        }

        return acts;
    }
}