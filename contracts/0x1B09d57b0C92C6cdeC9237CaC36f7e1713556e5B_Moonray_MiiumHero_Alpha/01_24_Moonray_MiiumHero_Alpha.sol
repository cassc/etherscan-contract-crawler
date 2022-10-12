// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Moonray_MiiumHero_AlphaBase.sol';
import './Moonray_MiiumHero_AlphaSplitsAndRoyalties.sol';

/**
 * @title Moonray_MiiumHero_Alpha
 */
contract Moonray_MiiumHero_Alpha is Moonray_MiiumHero_AlphaSplitsAndRoyalties, Moonray_MiiumHero_AlphaBase {
    constructor()
        Moonray_MiiumHero_AlphaBase(
            'Moonray_MiiumHero_Alpha',
            'MNRY_MH_1',
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
            1001120,
            .025 ether,
            253,
            0,
            'QmS2egivJzgvx8Zua9yBxSDJhwNc5mm2Yocu9aRV1z2jxB/token1'
        );

        TokenFlavor[] memory initialFlavors = new TokenFlavor[](1);

        initialFlavors[0] = gold;

        return initialFlavors;
    }
}