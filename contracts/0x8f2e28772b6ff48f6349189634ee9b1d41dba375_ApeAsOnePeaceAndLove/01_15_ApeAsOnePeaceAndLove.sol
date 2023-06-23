// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./NFTCollection/presets/NFTCollectionPresetMintByBurn.sol";

contract ApeAsOnePeaceAndLove is NFTCollectionPresetMintByBurn {
    constructor()
        NFTCollectionPresetMintByBurn(
            "APE as ONE: Peace & Love", // Name
            "AAS1PL", // Symbol
            "ipfs://QmRRRL2VrfuqqfPhrLAb7Urkfcm6rRGbspX8dDpNiBSBJ2/", // Base URI
            1, // Cost to mint
            8888, // Max supply
            0xa0A922EE2fA0eeDB2a2e813E2aa02b34B7A05d2f, // Contract owner
            0xa0A922EE2fA0eeDB2a2e813E2aa02b34B7A05d2f, // Royalties receiver
            750, // Royalties percentage
            0x5A87D5CF256049B2132a234E94613786071947BC // Serum address
        )
    {
        revealed = true;
    }
}