// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';

import { MarketPlaceHelperProxy } from '../helpers/MarketPlaceHelperProxy.sol';
import { IShardVaultProxy } from './IShardVaultProxy.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Upgradeable proxy with externally controlled ShardVault implementation
 */
contract ShardVaultProxy is Proxy, IShardVaultProxy {
    address private immutable SHARD_VAULT_DIAMOND;

    constructor(
        ShardVaultAddresses memory addresses,
        ShardVaultUints memory uints,
        string memory name,
        string memory symbol,
        string memory baseURI,
        bool isPUSDVault
    ) {
        SHARD_VAULT_DIAMOND = addresses.shardVaultDiamond;

        OwnableStorage.layout().owner = msg.sender;

        ERC721MetadataStorage.Layout storage metadata = ERC721MetadataStorage
            .layout();
        metadata.name = name;
        metadata.symbol = symbol;
        metadata.baseURI = baseURI;

        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        address marketPlaceHelperProxy = address(
            new MarketPlaceHelperProxy(addresses.marketPlaceHelper)
        );
        emit MarketPlaceHelperProxyDeployed(marketPlaceHelperProxy);

        l.marketPlaceHelper = marketPlaceHelperProxy;
        l.collection = addresses.collection;
        l.jpegdVault = addresses.jpegdVault;
        l.jpegdVaultHelper = addresses.jpegdVaultHelper;
        l.shardValue = uints.shardValue;
        l.maxSupply = uints.maxSupply;
        l.maxMintBalance = uints.maxMintBalance;

        l.saleFeeBP = uints.saleFeeBP;
        l.acquisitionFeeBP = uints.acquisitionFeeBP;
        l.yieldFeeBP = uints.yieldFeeBP;
        l.ltvBufferBP = uints.ltvBufferBP;
        l.ltvDeviationBP = uints.ltvDeviationBP;
        l.isPUSDVault = isPUSDVault;

        uint256 authorizedLength = addresses.authorized.length;
        unchecked {
            for (uint256 i; i < authorizedLength; ++i) {
                l.authorized[addresses.authorized[i]] = true;
            }
        }
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(SHARD_VAULT_DIAMOND).facetAddress(msg.sig);
    }

    receive() external payable {}
}