// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';

import { ERC1155MetadataExtensionInternal } from './ERC1155MetadataExtensionInternal.sol';
import { SimpleVaultStorage } from './SimpleVaultStorage.sol';

/**
 * @title Upgradeable proxy with externally controlled SimpleVault implementation
 */
contract SimpleVaultProxy is
    Proxy,
    OwnableInternal,
    ERC1155MetadataExtensionInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;

    address private immutable SIMPLE_VAULT_DIAMOND;

    constructor(
        address simpleVaultDiamond,
        address whitelist,
        uint256 shardValue,
        uint64 maxSupply,
        uint64 maxMintBalance,
        uint16 acquisitionFeeBP,
        uint16 saleFeeBP,
        address[] memory collections,
        string memory name,
        string memory symbol
    ) {
        SIMPLE_VAULT_DIAMOND = simpleVaultDiamond;

        _setOwner(msg.sender);

        _setName(name);
        _setSymbol(symbol);

        SimpleVaultStorage.Layout storage l = SimpleVaultStorage.layout();

        l.whitelist = whitelist;
        l.shardValue = shardValue;
        l.maxSupply = maxSupply;
        l.maxMintBalance = maxMintBalance;

        l.acquisitionFeeBP = acquisitionFeeBP;
        l.saleFeeBP = saleFeeBP;

        uint256 collectionsLength = collections.length;
        unchecked {
            for (uint256 i; i < collectionsLength; ++i) {
                l.vaultCollections.add(collections[i]);
            }
        }
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(SIMPLE_VAULT_DIAMOND).facetAddress(msg.sig);
    }

    /**
     * @notice required in order to accept ETH in exchange for minting shards
     */
    receive() external payable {}
}