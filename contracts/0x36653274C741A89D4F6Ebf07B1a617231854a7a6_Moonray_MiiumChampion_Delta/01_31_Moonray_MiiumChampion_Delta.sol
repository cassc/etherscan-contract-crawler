// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Moonray_MiiumChampion_DeltaBase.sol';
import './Moonray_MiiumChampion_DeltaSplitsAndRoyalties.sol';

/**
 * @title Moonray_MiiumChampion_Delta
 */
contract Moonray_MiiumChampion_Delta is Moonray_MiiumChampion_DeltaSplitsAndRoyalties, Moonray_MiiumChampion_DeltaBase {
    constructor()
        Moonray_MiiumChampion_DeltaBase(
            'Moonray_MiiumChampion_Delta',
            'MNRY_MC_4',
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
        TokenFlavor memory orangeAndGrey = TokenFlavor(
            1104400,
            .025 ether,
            500,
            0,
            'QmVqfJ8M6iLKHZpdX79qreaPU2Wzs9Pngb27vZuwfzt4cG/token1'
        );

        TokenFlavor[] memory initialFlavors = new TokenFlavor[](1);

        initialFlavors[0] = orangeAndGrey;

        return initialFlavors;
    }
}