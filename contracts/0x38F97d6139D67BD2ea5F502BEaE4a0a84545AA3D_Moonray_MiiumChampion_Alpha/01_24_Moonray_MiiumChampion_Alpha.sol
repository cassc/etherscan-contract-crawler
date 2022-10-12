// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Moonray_MiiumChampion_AlphaBase.sol';
import './Moonray_MiiumChampion_AlphaSplitsAndRoyalties.sol';

/**
 * @title Moonray_MiiumChampion_Alpha
 */
contract Moonray_MiiumChampion_Alpha is Moonray_MiiumChampion_AlphaSplitsAndRoyalties, Moonray_MiiumChampion_AlphaBase {
    constructor()
        Moonray_MiiumChampion_AlphaBase(
            'Moonray_MiiumChampion_Alpha',
            'MNRY_MC_1',
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
        TokenFlavor memory silver = TokenFlavor(
            1101110,
            .025 ether,
            56,
            0,
            'QmPCYD5DoKfgGSN9PXtUkJzarvz18D81kvTSJszaWmcPoC/token1'
        );

        TokenFlavor[] memory initialFlavors = new TokenFlavor[](1);

        initialFlavors[0] = silver;

        return initialFlavors;
    }
}