// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Moonray_MiiumChampion_BetaBase.sol';
import './Moonray_MiiumChampion_BetaSplitsAndRoyalties.sol';

/**
 * @title Moonray_MiiumChampion_Beta
 */
contract Moonray_MiiumChampion_Beta is Moonray_MiiumChampion_BetaSplitsAndRoyalties, Moonray_MiiumChampion_BetaBase {
    constructor()
        Moonray_MiiumChampion_BetaBase(
            'Moonray_MiiumChampion_Beta',
            'MNRY_MC_2',
            'https://nftculture.mypinata.cloud/ipfs/',
            addresses,
            splits,
            0.025 ether,
            0.025 ether,
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
        TokenFlavor memory glowingGreen = TokenFlavor(
            1102600,
            .025 ether,
            500,
            0,
            'QmPX4TcPcAGyiedD4av2kV4Hu16VydN54zxVqDbo4psUgj/token1'
        );

        TokenFlavor[] memory initialFlavors = new TokenFlavor[](1);

        initialFlavors[0] = glowingGreen;

        return initialFlavors;
    }
}