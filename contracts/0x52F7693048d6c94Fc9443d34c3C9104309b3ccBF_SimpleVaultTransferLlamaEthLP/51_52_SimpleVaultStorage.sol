// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { ISimpleVaultInternal } from './ISimpleVaultInternal.sol';
import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';

library SimpleVaultStorage {
    struct Layout {
        uint256 shardValue;
        uint256 accruedFees;
        //maximum tokens of MINT_TOKEN_ID which may be minted from deposits.
        //will be set to current totalSupply of MINT_TOKEN_ID if ERC721 asset
        //is purchased by vault prior to maxSupply of shards being minted
        uint64 maxSupply;
        uint16 saleFeeBP;
        uint16 acquisitionFeeBP;
        address whitelist;
        uint64 maxMintBalance;
        uint64 reservedSupply;
        uint48 whitelistEndsAt;
        bool isEnabled;
        bool isYieldClaiming;
        EnumerableSet.AddressSet vaultCollections;
        //registered all ids of ERC721 tokens acquired by vault - was replaced with collectionOwnedTokenIds
        //in order to allow for same id from different collections to be owned
        EnumerableSet.UintSet _deprecated_ownedtokenIds;
        mapping(address collection => mapping(uint256 tokenId => uint256 price)) priceOfSale;
        mapping(address collection => EnumerableSet.UintSet ownedTokenIds) collectionOwnedTokenIds;
        uint32 ownedTokenAmount;
        uint256 cumulativeETHPerShard;
        uint16 yieldFeeBP;
        uint16 ltvBufferBP;
        uint16 ltvDeviationBP;
        mapping(address collection => EnumerableSet.UintSet tokenIds) collateralizedTokens;
        mapping(address account => uint256 amount) ethDeductionsPerShard; //total amount of ETH deducted per shard, used to account for user rewards
        mapping(address account => uint256 amount) userETHYield;
        mapping(address account => bool isAuthorized) isAuthorized;
        mapping(ISimpleVaultInternal.StakingAdaptor adaptor => bool isActivated) activatedStakingAdaptors;
        mapping(ISimpleVaultInternal.LendingAdaptor adaptor => bool isActivated) activatedLendingAdaptors;
        mapping(address collection => mapping(uint256 tokenId => uint256 amount)) collectionOwnedTokenAmounts;
        mapping(address collection => mapping(uint256 tokenId => uint256 amount)) collateralizedTokenAmounts;
        mapping(address collection => mapping(uint256 tokenId => mapping(uint256 amount => EnumerableSet.UintSet))) priceOfSales;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insrt.contracts.storage.SimpleVault');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}