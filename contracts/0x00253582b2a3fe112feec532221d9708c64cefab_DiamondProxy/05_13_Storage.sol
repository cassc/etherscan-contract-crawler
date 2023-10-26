// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IERC20 } from "oz/token/ERC20/IERC20.sol";

import { IAccessControlManager } from "interfaces/IAccessControlManager.sol";
import { IAgToken } from "interfaces/IAgToken.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                        ENUMS                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

enum FacetCutAction {
    Add,
    Replace,
    Remove
}

enum ManagerType {
    EXTERNAL
}

enum ActionType {
    Mint,
    Burn,
    Redeem
}

enum TrustedType {
    Updater,
    Seller
}

enum QuoteType {
    MintExactInput,
    MintExactOutput,
    BurnExactInput,
    BurnExactOutput
}

enum OracleReadType {
    CHAINLINK_FEEDS,
    EXTERNAL,
    NO_ORACLE,
    STABLE,
    WSTETH,
    CBETH,
    RETH,
    SFRXETH,
    PYTH
}

enum OracleQuoteType {
    UNIT,
    TARGET
}

enum WhitelistType {
    BACKED
}

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    STRUCTS                                                     
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

struct Permit2Details {
    address to;                                  // Address that will receive the funds
    uint256 nonce;                               // Nonce of the transaction
    bytes signature;                             // Permit signature of the user
}       

struct FacetCut {
    address facetAddress;                        // Facet contract address
    FacetCutAction action;                       // Can be add, remove or replace
    bytes4[] functionSelectors;                  // Ex. bytes4(keccak256("transfer(address,uint256)"))
}

struct Facet {
    address facetAddress;                        // Facet contract address
    bytes4[] functionSelectors;                  // Ex. bytes4(keccak256("transfer(address,uint256)"))
}

struct FacetInfo {
    address facetAddress;                        // Facet contract address
    uint16 selectorPosition;                     // Position in the list of all selectors
}

struct DiamondStorage {
    bytes4[] selectors;                          // List of all available selectors
    mapping(bytes4 => FacetInfo) selectorInfo;   // Selector to (address, position in list)
    IAccessControlManager accessControlManager;  // Contract handling access control
}

struct ImplementationStorage {
    address implementation;                      // Dummy implementation address for Etherscan usability
}

struct ManagerStorage {
    IERC20[] subCollaterals;                     // Subtokens handled by the manager or strategies
    bytes config;                                // Additional configuration data
}

struct Collateral {
    uint8 isManaged;                             // If the collateral is managed through external strategies
    uint8 isMintLive;                            // If minting from this asset is unpaused
    uint8 isBurnLive;                            // If burning to this asset is unpaused
    uint8 decimals;                              // IERC20Metadata(collateral).decimals()
    uint8 onlyWhitelisted;                       // If only whitelisted addresses can burn or redeem for this token
    uint216 normalizedStables;                   // Normalized amount of stablecoins issued from this collateral
    uint64[] xFeeMint;                           // Increasing exposures in [0,BASE_9[
    int64[] yFeeMint;                            // Mint fees at the exposures specified in `xFeeMint`
    uint64[] xFeeBurn;                           // Decreasing exposures in ]0,BASE_9]
    int64[] yFeeBurn;                            // Burn fees at the exposures specified in `xFeeBurn`
    bytes oracleConfig;                          // Data about the oracle used for the collateral
    bytes whitelistData;                         // For whitelisted collateral, data used to verify whitelists
    ManagerStorage managerData;                  // For managed collateral, data used to handle the strategies
}

struct TransmuterStorage {
    IAgToken agToken;                            // agToken handled by the system
    uint8 isRedemptionLive;                      // If redemption is unpaused
    uint8 statusReentrant;                        // If call is reentrant or not
    uint128 normalizedStables;                   // Normalized amount of stablecoins issued by the system
    uint128 normalizer;                          // To reconcile `normalizedStables` values with the actual amount
    address[] collateralList;                    // List of collateral assets supported by the system
    uint64[] xRedemptionCurve;                   // Increasing collateral ratios > 0
    int64[] yRedemptionCurve;                    // Value of the redemption fees at `xRedemptionCurve`
    mapping(address => Collateral) collaterals;  // Maps a collateral asset to its parameters
    mapping(address => uint256) isTrusted;       // If an address is trusted to update the normalizer value
    mapping(address => uint256) isSellerTrusted; // If an address is trusted to sell accruing reward tokens
    mapping(WhitelistType => mapping(address => uint256)) isWhitelistedForType;
                                                 // Whether an address is whitelisted for a specific whitelist type
}