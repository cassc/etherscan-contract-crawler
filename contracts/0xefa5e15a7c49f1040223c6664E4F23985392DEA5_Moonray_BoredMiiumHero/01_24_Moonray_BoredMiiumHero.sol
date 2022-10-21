// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Moonray_BoredMiiumHeroBase.sol';
import './Moonray_BoredMiiumHeroSplitsAndRoyalties.sol';

/**
 * @title Moonray_BoredMiiumHero
 */
contract Moonray_BoredMiiumHero is Moonray_BoredMiiumHeroSplitsAndRoyalties, Moonray_BoredMiiumHeroBase {
    constructor()
        Moonray_BoredMiiumHeroBase(
            'Moonray_BoredMiiumHero',
            'MNRY_BMH',
            'ipfs://',
            addresses,
            splits,
            0.999 ether
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
        TokenFlavor memory bored_green = TokenFlavor(
            1002601,
            0.999 ether,
            1000,
            0,
            'QmW5B8QgyRm7oFPubiSowt6DKcmZ6V9xPhtZ1wVkZ3vrk1/token1'
        );

        TokenFlavor memory bored_gold = TokenFlavor(
            1002120,
            0.999 ether,
            10,
            0,
            'QmW5B8QgyRm7oFPubiSowt6DKcmZ6V9xPhtZ1wVkZ3vrk1/token2'
        );

        TokenFlavor[] memory initialFlavors = new TokenFlavor[](3);

        initialFlavors[0] = bored_green;
        initialFlavors[1] = bored_gold;

        return initialFlavors;
    }
}