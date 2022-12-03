//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4; 

/**
 * @dev Interface used to share common types between AsyncArt Blueprints contracts
 * @author Ohimire Labs
 */
interface IBlueprintTypes {
    /**
     * @dev Core administrative accounts 
     * @param platform Platform, holder of DEFAULT_ADMIN role
     * @param minter Minter, holder of MINTER_ROLE
     * @param asyncSaleFeesRecipient Recipient of primary sale fees going to platform
     */
    struct Admins {
        address platform;
        address minter;
        address asyncSaleFeesRecipient;
    } 

    /**
     * @dev Object passed in when preparing blueprint 
     * @param _capacity Number of NFTs in Blueprint 
     * @param _price Price per NFT in Blueprint
     * @param _erc20Token Address of ERC20 currency required to buy NFTs, can be zero address if expected currency is native gas token 
     * @param _blueprintMetaData Blueprint metadata uri
     * @param _baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param _merkleroot Root of Merkle tree holding whitelisted accounts 
     * @param _mintAmountArtist Amount of NFTs of Blueprint mintable by artist
     * @param _mintAmountPlatform Amount of NFTs of Blueprint mintable by platform 
     * @param _maxPurchaseAmount Max number of NFTs purchasable in a single transaction
     * @param _saleEndTimestamp Timestamp when the sale ends 
     */ 
    struct BlueprintPreparationConfig {
        uint64 _capacity;
        uint128 _price;
        address _erc20Token;
        string _blueprintMetaData;
        string _baseTokenUri;
        bytes32 _merkleroot;
        uint32 _mintAmountArtist;
        uint32 _mintAmountPlatform;
        uint64 _maxPurchaseAmount;
        uint128 _saleEndTimestamp;
    }

    /**
     * @dev Object holding primary fee data
     * @param primaryFeeBPS Primary fee percentage allocations, in basis points
     * @param primaryFeeRecipients Primary fee recipients 
     */
    struct PrimaryFees {
        uint32[] primaryFeeBPS;
        address[] primaryFeeRecipients;
    }
}