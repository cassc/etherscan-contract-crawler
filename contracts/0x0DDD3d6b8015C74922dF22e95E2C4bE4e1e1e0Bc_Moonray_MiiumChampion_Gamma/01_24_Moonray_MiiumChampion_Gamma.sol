// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Moonray_MiiumChampion_GammaBase.sol';
import './Moonray_MiiumChampion_GammaSplitsAndRoyalties.sol';

/**
 * @title Moonray_MiiumChampion_Gamma
 */
contract Moonray_MiiumChampion_Gamma is Moonray_MiiumChampion_GammaSplitsAndRoyalties, Moonray_MiiumChampion_GammaBase {
    constructor()
        Moonray_MiiumChampion_GammaBase(
            'Moonray_MiiumChampion_Gamma',
            'MNRY_MC_3',
            'https://nftculture.mypinata.cloud/ipfs/',
            addresses,
            splits,
            0.025 ether
        )
    {
        // Implementation version: v1.0.0
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AExpandable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _getInitialFlavors() internal pure override returns (TokenFlavor[] memory) {
        TokenFlavor memory gold = TokenFlavor(
            1103120,
            .025 ether,
            128,
            0,
            'QmSEqfLzdoRrx7ksdK3g6C3xxpgKAZcreurJTSWVd7E9Nk/token1'
        );

        TokenFlavor[] memory initialFlavors = new TokenFlavor[](1);

        initialFlavors[0] = gold;

        return initialFlavors;
    }
}