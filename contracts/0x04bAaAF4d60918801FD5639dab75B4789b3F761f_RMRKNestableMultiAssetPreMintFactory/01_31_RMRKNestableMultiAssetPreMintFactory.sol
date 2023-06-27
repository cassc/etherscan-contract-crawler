// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../../implementations/premint/RMRKNestableMultiAssetPreMintMP.sol";
import "../../interfaces/IRMRKRegistry.sol";
import "../IRMRKFactory.sol";

contract RMRKNestableMultiAssetPreMintFactory is IRMRKFactory {
    IRMRKRegistry private _rmrkRegistry;

    constructor(address rmrkRegistry) {
        _rmrkRegistry = IRMRKRegistry(rmrkRegistry);
    }

    function deployRMRKCollection(
        string memory name,
        string memory symbol,
        string memory collectionMetadata,
        string memory tokenURI,
        InitData memory data
    ) external {
        RMRKNestableMultiAssetPreMintMP nestableContract = new RMRKNestableMultiAssetPreMintMP(
                name,
                symbol,
                collectionMetadata,
                tokenURI,
                data
            );

        nestableContract.manageContributor(
            _rmrkRegistry.getMetaFactoryAddress(),
            true
        );
        nestableContract.transferOwnership(msg.sender);

        _rmrkRegistry.addCollectionFromFactories(
            address(nestableContract),
            msg.sender,
            data.maxSupply,
            IRMRKRegistry.LegoCombination.NestableMultiAsset,
            IRMRKRegistry.MintingType.RMRKPreMint,
            false
        );
    }
}