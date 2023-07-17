// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../../implementations/premint/RMRKEquippablePreMintMP.sol";
import "../../interfaces/IRMRKRegistry.sol";
import "../IRMRKFactory.sol";

contract RMRKEquippablePreMintFactory is IRMRKFactory {
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
        RMRKEquippablePreMintMP equippableContract = new RMRKEquippablePreMintMP(
                name,
                symbol,
                collectionMetadata,
                tokenURI,
                data
            );

        equippableContract.manageContributor(
            _rmrkRegistry.getMetaFactoryAddress(),
            true
        );
        equippableContract.transferOwnership(msg.sender);

        _rmrkRegistry.addCollectionFromFactories(
            address(equippableContract),
            msg.sender,
            data.maxSupply,
            IRMRKRegistry.LegoCombination.Equippable,
            IRMRKRegistry.MintingType.RMRKPreMint,
            false
        );
    }
}