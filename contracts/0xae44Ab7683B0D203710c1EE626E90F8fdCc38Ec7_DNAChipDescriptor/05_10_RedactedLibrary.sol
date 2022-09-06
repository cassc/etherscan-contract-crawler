// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library RedactedLibrary {
    struct Traits {
        uint256 base;
        uint256 earrings;
        uint256 eyes;
        uint256 hats;
        uint256 mouths;
        uint256 necks;
        uint256 noses;
        uint256 whiskers;
    }

    struct TightTraits {
        uint8 base;
        uint8 earrings;
        uint8 eyes;
        uint8 hats;
        uint8 mouths;
        uint8 necks;
        uint8 noses;
        uint8 whiskers;
    }

    function traitsToRepresentation(Traits memory traits) internal pure returns (uint256) {
        uint256 representation = uint256(traits.base);
        representation |= traits.earrings << 8;
        representation |= traits.eyes << 16;
        representation |= traits.hats << 24;
        representation |= traits.mouths << 32;
        representation |= traits.necks << 40;
        representation |= traits.noses << 48;
        representation |= traits.whiskers << 56;

        return representation;
    }

    function representationToTraits(uint256 representation) internal pure returns (Traits memory traits) {
        traits.base = uint8(representation);
        traits.earrings = uint8(representation >> 8);
        traits.eyes = uint8(representation >> 16);
        traits.hats = uint8(representation >> 24);
        traits.mouths = uint8(representation >> 32);
        traits.necks = uint8(representation >> 40);
        traits.noses = uint8(representation >> 48);
        traits.whiskers = uint8(representation >> 56);
    }

    function representationToTraitsArray(uint256 representation) internal pure returns (uint8[8] memory traitsArray) {
        traitsArray[0] = uint8(representation); // base
        traitsArray[1] = uint8(representation >> 8); // earrings
        traitsArray[2] = uint8(representation >> 16); // eyes
        traitsArray[3] = uint8(representation >> 24); // hats
        traitsArray[4] = uint8(representation >> 32); // mouths
        traitsArray[5] = uint8(representation >> 40); // necks
        traitsArray[6] = uint8(representation >> 48); // noses
        traitsArray[7] = uint8(representation >> 56); // whiskers
    }
}