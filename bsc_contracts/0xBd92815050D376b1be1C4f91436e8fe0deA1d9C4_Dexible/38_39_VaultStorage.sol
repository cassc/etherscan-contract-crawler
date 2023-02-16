//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../token/IDXBL.sol";
import "./interfaces/IPriceFeed.sol";

library VaultStorage {

    bytes32 constant VAULT_STORAGE_KEY = 0xbfa76ec2967ed7f8d3d40cd552f1451ab03573b596bfce931a6a016f7733078c;

    
    //mint rate bucket
    struct MintRateRangeConfig {
        uint16 minMMVolume;
        uint16 maxMMVolume;
        uint rate;
    }

    //fee token and its associated chainlink feed
    struct FeeTokenConfig {
        address[] feeTokens;
        address[] priceFeeds;
    }

    //initialize config to intialize storage
    struct VaultConfig {

        //the address of the wrapped native token
        address wrappedNativeToken;

        //address of the multisig that will administer this vault
        address adminMultiSig;


        //seconds for any timelock-based changes
        uint32 timelockSeconds;

        //starting volume needed to mint a single DXBL token. This increases
        //as we get closer to reaching the daily goal
        uint baseMintThreshold;

        //initial rate ranges to apply
        MintRateRangeConfig[] rateRanges;

        //set of fee token/price feed pairs to initialize with
        FeeTokenConfig feeTokenConfig;
    }

    //stored mint rate range
    struct MintRateRange {
        uint16 minMMVolume;
        uint16 maxMMVolume;
        uint rate;
        uint index;
    }

    //price feed for a fee token
    struct PriceFeed {
        IPriceFeed feed;
        uint8 decimals;
    }

    /*****************************************************************************************
     * STORAGE
    ******************************************************************************************/
    
    
    struct VaultData {
        //whether the vault is paused
        bool paused;

        //admin multi sig
        address adminMultiSig;

        //token address
        IDXBL dxbl;

        //dexible settlement contract that is allowed to call the vault
        address dexible;

        //wrapped native asset address for gas computation
        address wrappedNativeToken;

        //pending migration to new vault
        address pendingMigrationTarget;

        //time before migration allowed
        uint32 timelockSeconds;

        //base volume needed to mint a single DXBL token. This increases
        //as we get closer to reaching the daily goal
        uint baseMintThreshold;

        //current daily volume adjusted each hour
        uint currentVolume;

        //to compute what hourly slots to deduct from 24hr window
        uint lastTradeTimestamp;

        //can migrate the contract to a new vault after this time
        uint migrateAfterTime;

        //all known fee tokens. Some may be inactive
        IERC20[] feeTokens;

        //the current volume range we're operating in for mint rate
        MintRateRange currentMintRate;

        //The ranges of 24hr volume and their percentage-per-MM increase to 
        //mint a single token
        MintRateRange[] mintRateRanges;

        //hourly volume totals to adjust current volume every 24 hr slot
        uint[24] hourlyVolume;

        //fee token decimals
        mapping(address => uint8) tokenDecimals;

        //all allowed fee tokens mapped to their price feed address
        mapping(address => PriceFeed) allowedFeeTokens;
    }

    /**
     * If a migration occurs from the V1 vault to a new vault, this structure is forwarded
     * after all fee token balances are transferred. It is expected that the new vault will have
     * its fee token, minting rates, and starting mint rates mapped out as part of its deployment.
     * The migration is intended to get the new vault into a state where it knows the last 24hrs
     * of volume and can pick up where this vault leaves off but with new settings and capabilities.
     */
    struct VaultMigrationV1 {
        //current daily volume adjusted each hour
        uint currentVolume;

        //to compute what hourly slots to deduct from 24hr window
        uint lastTradeTimestamp;

        //hourly volume totals to adjust in new contract
        uint[24] hourlyVolume;

        //the current volume range we're operating in for mint rate
        MintRateRange currentMintRate;
    }

    function load() internal pure returns (VaultData storage ds) {
        assembly { ds.slot := VAULT_STORAGE_KEY }
    }
}