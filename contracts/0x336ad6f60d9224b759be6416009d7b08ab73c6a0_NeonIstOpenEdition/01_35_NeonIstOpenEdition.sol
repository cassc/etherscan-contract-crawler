// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './NeonIstOpenEditionBase.sol';
import './NeonIstOpenEditionSplitsAndRoyalties.sol';

/**
 * @title NeonIstOpenEdition
 */
contract NeonIstOpenEdition is NeonIstOpenEditionSplitsAndRoyalties, NeonIstOpenEditionBase {
    constructor()
        NeonIstOpenEditionBase(
            'NeonIstOpenEdition',
            'NIOE',
            'ipfs://QmaPpddSXAj8wKeya4cT8D2u5nyhRF7DhbaNSVcWnbus7S/',
            addresses,
            splits
        )
    {
        // Implementation version: v1.0.0
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A_NFTCExtended_Expandable, ERC2981) returns (bool) {
        return ERC721A_NFTCExtended_Expandable.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function _getInitialFlavors() internal pure override returns (FlavorInfo[] memory) {
        FlavorInfo[] memory initialFlavors = new FlavorInfo[](1);
        initialFlavors[0] = FlavorInfo(500000, 0.06 ether, 0, 0, 'token39'); // 0 Max Supply is Open Edition
        return initialFlavors;
    }
}