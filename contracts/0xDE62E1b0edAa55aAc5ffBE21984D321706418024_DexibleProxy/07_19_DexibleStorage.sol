//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../token/IDXBL.sol";
import "./oracles/IArbitrumGasOracle.sol";
import "../vault/interfaces/ICommunityVault.sol";
import "./oracles/IStandardGasAdjustments.sol";

library DexibleStorage {
    bytes32 constant DEXIBLE_STORAGE_KEY = 0x949817a987a8e038ef345d3c9d4fd28e49d8e4e09456e57c05a8b2ce2e62866c;

    //primary initialization config settings
    struct DexibleConfig {
        
        //percent to split to revshare
        uint8 revshareSplitRatio;

        //std bps rate to apply to all trades
        uint16 stdBpsRate;

        //minimum bps rate regardless of tokens held
        uint16 minBpsRate;

        //multi sig allowed to change settings
        address adminMultiSig;

        //the vault contract
        address communityVault;

        //treasury for Dexible team
        address treasury;

        //the DXBL token address
        address dxblToken;

        //arbitrum gas oracle contract address
        address arbGasOracle;

        //contract that manages the standard gas adjustment types
        address stdGasAdjustment;

        //minimum flat fee to charge if bps fee is too low
        uint112 minFeeUSD;

        //whitelisted relays to allow
        address[] initialRelays;

    }

    /**
     * This is the primary storage for Dexible operations.
     */
    struct DexibleData {

        //whether contract has been paused
        bool paused;

        //how much of fee goes to revshare vault
        uint8 revshareSplitRatio;
         
        //standard bps fee rate
        uint16 stdBpsRate;

        //minimum fee applied regardless of tokens held
        uint16 minBpsRate;

        //min fee to charge if bps too low
        uint112 minFeeUSD;
        
        //vault address
        ICommunityVault communityVault;

        //treasury address
        address treasury;

        //multi-sig that manages this contract
        address adminMultiSig;

        //the DXBL token
        IDXBL dxblToken;

        //gas oracle for arb network
        IArbitrumGasOracle arbitrumGasOracle;

        IStandardGasAdjustments stdGasAdjustment;

        //whitelisted relay wallets
        mapping(address => bool) relays;
    }

    function load() internal pure returns (DexibleData storage ds) {
        assembly { ds.slot := DEXIBLE_STORAGE_KEY }
    }
}