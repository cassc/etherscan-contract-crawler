// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

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
        EnumerableSet.UintSet ownedTokenIds;
        mapping(address collection => mapping(uint256 tokenId => uint256 price)) priceOfSale;
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