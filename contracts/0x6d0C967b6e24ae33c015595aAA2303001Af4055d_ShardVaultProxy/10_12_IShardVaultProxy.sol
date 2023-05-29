// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IShardVaultProxy {
    /**
     * @notice emitted upon MarketPlaceHelperProxy deployment
     */
    event MarketPlaceHelperProxyDeployed(address marketPlacerHelperProxy);

    /**
     * @param shardVaultDiamond the address of the shard vault diamond\
     * @param marketPlaceHelper the address of the marketplace helper implementation
     * @param collection the address of the NFT collection contract
     * @param jpegdVault the jpeg'd NFT vault corresponding to the collection
     * @param jpegdVaultHelper the jpeg'd NFT Vault helper contract used for
       non-ERC721/1155 compiant collections
     * @param authorized array of authorized addresses for loan health maintenance
     */
    struct ShardVaultAddresses {
        address shardVaultDiamond;
        address marketPlaceHelper;
        address collection;
        address jpegdVault;
        address jpegdVaultHelper;
        address whitelist;
        address[] authorized;
    }

    /**
     * @param shardValue the ETH value of each shard
     * @param maxSupply maximum shards to be minted by vault
     * @param maxMintBalance maximum amount of shards allowed per user
     * @param saleFeeBP sale fee in basis points
     * @param acquisitionFeeBP acquisition fee in basis points
     * @param yieldFeeBP yield fee in basis points
     * @param ltvBufferBP loan to value buffer in basis points
     * @param ltvDeviationBP loan to value buffer deviation in basis points
     */
    struct ShardVaultUints {
        uint256 shardValue;
        uint64 maxSupply;
        uint64 maxMintBalance;
        uint16 saleFeeBP;
        uint16 acquisitionFeeBP;
        uint16 yieldFeeBP;
        uint16 ltvBufferBP;
        uint16 ltvDeviationBP;
    }
}