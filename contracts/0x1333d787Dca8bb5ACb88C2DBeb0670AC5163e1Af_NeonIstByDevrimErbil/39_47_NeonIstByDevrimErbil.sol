// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './NeonIstByDevrimErbilBase.sol';
import './NeonIstByDevrimErbilSplitsAndRoyalties.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contracts-private/contracts/token/IFlavorInfoProvider.sol';

/**
 * @title NeonIstByDevrimErbil
 */
contract NeonIstByDevrimErbil is NeonIstByDevrimErbilSplitsAndRoyalties, NeonIstByDevrimErbilBase {
    constructor()
        NeonIstByDevrimErbilBase(
            'NeonIstByDevrimErbil',
            'NIDE',
            'ipfs://QmcCuTxNDUzr73tVLbCJM6BfuJTFmCWMAvaZ2jkjczYYDe/',
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
        initialFlavors[0] = FlavorInfo(100000, 10 ether, 1, 0, 'token1');
        return initialFlavors;
    }

    function injectFlavors(address __externalProviderAddress) external onlyOwner {
        IFlavorInfoProvider externalProvider = IFlavorInfoProvider(__externalProviderAddress);

        FlavorInfo[] memory flavors = externalProvider.provideFlavorInfos();

        for (uint256 idx = 0; idx < flavors.length; idx++) {
            _incrementMaxSupply(flavors[idx].maxSupply);
            _createFlavorInfo(flavors[idx]);
        }
    }
}