// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Moonray_MiiumVaronis_AlphaBase.sol';
import './Moonray_MiiumVaronis_AlphaSplitsAndRoyalties.sol';

/**
 * @title Moonray_MiiumVaronis_Alpha
 */
contract Moonray_MiiumVaronis_Alpha is Moonray_MiiumVaronis_AlphaSplitsAndRoyalties, Moonray_MiiumVaronis_AlphaBase {
    constructor()
        Moonray_MiiumVaronis_AlphaBase(
            'Moonray_MiiumVaronis_Alpha',
            'MNRY_MV_1',
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
        TokenFlavor memory purpleAndBlue = TokenFlavor(
            1201900,
            .025 ether,
            500,
            0,
            'Qmec9T4eps3AjHmY2ihfUhC8KcmHww1PbLVZLg2FiNjNKe/token1'
        );

        TokenFlavor[] memory initialFlavors = new TokenFlavor[](1);

        initialFlavors[0] = purpleAndBlue;

        return initialFlavors;
    }
}