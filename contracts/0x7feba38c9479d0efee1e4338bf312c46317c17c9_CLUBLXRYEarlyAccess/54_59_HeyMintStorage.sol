// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct BaseConfig {
    // Used to create a default HeyMint Launchpad URI for token metadata to save gas over setting a custom URI and increase fetch reliability
    uint24 projectId;
    // If true, the default CORI subscription address will be used to enforce royalties with the Operator Filter Registry
    bool enforceRoyalties;
    // The royalty payout percentage in basis points
    uint16 royaltyBps;
    // If true, HeyMint fees will be charged for minting tokens
    bool heyMintFeeActive;
    // The address used to sign and validate presale mints
    address presaleSignerAddress;
    // The base URI for all token metadata
    string uriBase;
}

struct TokenConfig {
    uint16 tokenId;
    // Maximum supply of tokens that can be minted
    uint16 maxSupply;
    // If true tokens can be minted in the public sale
    bool publicSaleActive;
    // The price of a token in the public sale in 1/100,000 ETH - e.g. 1 = 0.00001 ETH, 100,000 = 1 ETH - multiply by 10^13 to get correct wei amount
    uint32 publicPrice;
    // The number of tokens that can be minted in the public sale per address
    uint8 publicMintsAllowedPerAddress;
    // If enabled, automatic start and stop times for the public sale will be enforced, otherwise ignored
    bool usePublicSaleTimes;
    // The automatic start time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
    uint32 publicSaleStartTime;
    // The automatic end time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
    uint32 publicSaleEndTime;
    // If true tokens can be minted in the presale
    bool presaleActive;
    // The price of a token in the presale in 1/100,000 ETH
    uint32 presalePrice;
    // Total number of tokens available for minting in the presale
    uint16 presaleMaxSupply;
    // The number of tokens that can be minted in the presale per address
    uint8 presaleMintsAllowedPerAddress;
    // The uri for this token (defaults to using uriBase if not set).
    string tokenUri;
    // If enabled, automatic start and stop times for the presale will be enforced, otherwise ignored
    bool usePresaleTimes;
    // The automatic start time for the presale (if usePresaleTimes is true and presaleActive is true)
    uint32 presaleStartTime;
    // The automatic end time for the presale (if usePresaleTimes is true and presaleActive is true)
    uint32 presaleEndTime;
    // Free claim
    address freeClaimContractAddress;
    uint16 mintsPerFreeClaim;
    bool freeClaimActive;
    // Burn to mint
    uint32 burnPayment;
    uint16 mintsPerBurn;
    bool burnClaimActive;
    // Soulbinding
    bool soulbindingActive;
    // If set, the UTC timestamp in seconds until which tokens are refundable for refundPrice
    uint32 refundEndsAt;
    // The amount returned to a user in a token refund in 1/100,000 ETH
    uint32 refundPrice;
}

struct AdvancedConfig {
    // Optional address where royalties are paid out. If not set, royalties are paid to the contract owner.
    address royaltyPayoutAddress;
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint16[] payoutBasisPoints;
    // The addresses to which funds are sent when a token is sold. If empty, funds are sent to the contract owner.
    address[] payoutAddresses;
    // Permanenetly disables the ability to change payout addresses or basis points.
    bool payoutAddressesFrozen;
    // Custom addresses that are allowed to call the 'creditCardMint' function.
    address[] creditCardMintAddresses;
    // Soulbinding
    bool soulbindAdminTransfersPermanentlyDisabled;
    address soulboundAdminAddress;
    // The address where refunded tokens are returned. If not set, refunded tokens are sent to the contract owner.
    address refundAddress;
}

struct Data {
    // ============ BASE FUNCTIONALITY ============
    // All token ids on the contract
    uint16[] tokenIds;
    // HeyMint fee to be paid per minted token (if not set, defaults to defaultHeymintFeePerToken)
    uint256 heymintFeePerToken;
    // Keeps track of if advanced config settings have been initialized to prevent setting multiple times
    bool advancedConfigInitialized;
    // Keeps track of how many of each token have been minted.
    mapping(uint16 => uint16) totalSupply;
    // Keeps track of how many tokens each address has minted.
    mapping(address => mapping(uint16 => uint16)) tokensMintedByAddress;
    // If minting a token has been permanently disabled.
    mapping(uint16 => bool) tokenMintingPermanentlyDisabled;
    // Keeps track of token ids that have been used for free claim.
    mapping(uint16 => mapping(uint256 => bool)) tokenFreeClaimUsed;
    // Used to allow an admin to transfer soulbound tokens when necessary
    bool soulboundAdminTransferInProgress;
    mapping(uint16 => bool) tokenMetadataFrozen;
    bool allMetadataFrozen;
}

struct BurnToken {
    // The contract address of the token to be burned
    address contractAddress;
    // The type of contract - 1 = ERC-721, 2 = ERC-1155
    uint8 tokenType;
    // The number of tokens to burn per mint
    uint8 tokensPerBurn;
    // The ID of the token on an ERC-1155 contract eligible for burn; unused for ERC-721
    uint16 tokenId;
}

library HeyMintStorage {
    struct State {
        string name;
        string symbol;
        BaseConfig cfg;
        mapping(uint16 => TokenConfig) tokens;
        mapping(uint16 => BurnToken[]) burnTokens;
        AdvancedConfig advCfg;
        Data data;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("heymint.launchpad.storage.erc1155");

    function state() internal pure returns (State storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}