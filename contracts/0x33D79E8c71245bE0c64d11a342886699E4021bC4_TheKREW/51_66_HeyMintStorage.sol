// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct BaseConfig {
    // If true tokens can be minted in the public sale
    bool publicSaleActive;
    // If enabled, automatic start and stop times for the public sale will be enforced, otherwise ignored
    bool usePublicSaleTimes;
    // If true tokens can be minted in the presale
    bool presaleActive;
    // If enabled, automatic start and stop times for the presale will be enforced, otherwise ignored
    bool usePresaleTimes;
    // If true, all tokens will be soulbound
    bool soulbindingActive;
    // If true, a random hash will be generated for each token
    bool randomHashActive;
    // If true, the default CORI subscription address will be used to enforce royalties with the Operator Filter Registry
    bool enforceRoyalties;
    // If true, HeyMint fees will be charged for minting tokens
    bool heyMintFeeActive;
    // The number of tokens that can be minted in the public sale per address
    uint8 publicMintsAllowedPerAddress;
    // The number of tokens that can be minted in the presale per address
    uint8 presaleMintsAllowedPerAddress;
    // The number of tokens that can be minted in the public sale per transaction
    uint8 publicMintsAllowedPerTransaction;
    // The number of tokens that can be minted in the presale sale per transaction
    uint8 presaleMintsAllowedPerTransaction;
    // Maximum supply of tokens that can be minted
    uint16 maxSupply;
    // Total number of tokens available for minting in the presale
    uint16 presaleMaxSupply;
    // The royalty payout percentage in basis points
    uint16 royaltyBps;
    // The price of a token in the public sale in 1/100,000 ETH - e.g. 1 = 0.00001 ETH, 100,000 = 1 ETH - multiply by 10^13 to get correct wei amount
    uint32 publicPrice;
    // The price of a token in the presale in 1/100,000 ETH
    uint32 presalePrice;
    // Used to create a default HeyMint Launchpad URI for token metadata to save gas over setting a custom URI and increase fetch reliability
    uint24 projectId;
    // The base URI for all token metadata
    string uriBase;
    // The address used to sign and validate presale mints
    address presaleSignerAddress;
    // The automatic start time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
    uint32 publicSaleStartTime;
    // The automatic end time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
    uint32 publicSaleEndTime;
    // The automatic start time for the presale (if usePresaleTimes is true and presaleActive is true)
    uint32 presaleStartTime;
    // The automatic end time for the presale (if usePresaleTimes is true and presaleActive is true)
    uint32 presaleEndTime;
    // If set, the UTC timestamp in seconds by which the fundingTarget must be met or funds are refundable
    uint32 fundingEndsAt;
    // The amount of centiETH that must be raised by fundingEndsAt or funds are refundable - multiply by 10^16
    uint32 fundingTarget;
}

struct AdvancedConfig {
    // When false, tokens cannot be staked but can still be unstaked
    bool stakingActive;
    // When false, tokens cannot be loaned but can still be retrieved
    bool loaningActive;
    // If true tokens can be claimed for free
    bool freeClaimActive;
    // The number of tokens that can be minted per free claim
    uint8 mintsPerFreeClaim;
    // Optional address of an NFT that is eligible for free claim
    address freeClaimContractAddress;
    // If true tokens can be burned in order to mint
    bool burnClaimActive;
    // If true, the original token id of a burned token will be used for metadata
    bool useBurnTokenIdForMetadata;
    // The number of tokens that can be minted per burn transaction
    uint8 mintsPerBurn;
    // The payment required alongside a burn transaction in order to mint in 1/100,000 ETH
    uint32 burnPayment;
    // Permanently freezes payout addresses and basis points so they can never be updated
    bool payoutAddressesFrozen;
    // If set, the UTC timestamp in seconds until which tokens are refundable for refundPrice
    uint32 refundEndsAt;
    // The amount returned to a user in a token refund in 1/100,000 ETH
    uint32 refundPrice;
    // Permanently freezes metadata so it can never be changed
    bool metadataFrozen;
    // If true the soulbind admin address is permanently disabled
    bool soulbindAdminTransfersPermanentlyDisabled;
    // If true deposit tokens can be burned in order to mint
    bool depositClaimActive;
    // If additional payment is required to mint, this is the amount required in centiETH
    uint32 remainingDepositPayment;
    // The deposit token smart contract address
    address depositContractAddress;
    // The merkle root used to validate if deposit tokens are eligible to burn to mint
    bytes32 depositMerkleRoot;
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint16[] payoutBasisPoints;
    // The addresses to which funds are sent when a token is sold. If empty, funds are sent to the contract owner.
    address[] payoutAddresses;
    // Optional address where royalties are paid out. If not set, royalties are paid to the contract owner.
    address royaltyPayoutAddress;
    // Used to allow transferring soulbound tokens with admin privileges. Defaults to the contract owner if not set.
    address soulboundAdminAddress;
    // The address where refunded tokens are returned. If not set, refunded tokens are sent to the contract owner.
    address refundAddress;
    // An address authorized to call the creditCardMint function.
    address creditCardMintAddress;
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

struct Data {
    // ============ BASE FUNCTIONALITY ============
    // HeyMint fee to be paid per minted token (if not set, defaults to defaultHeymintFeePerToken)
    uint256 heymintFeePerToken;
    // Keeps track of if advanced config settings have been initialized to prevent setting multiple times
    bool advancedConfigInitialized;
    // A mapping of token IDs to specific tokenURIs for tokens that have custom metadata
    mapping(uint256 => string) tokenURIs;
    // ============ CONDITIONAL FUNDING ============
    // If true, the funding target was reached and funds are not refundable
    bool fundingTargetReached;
    // If true, funding success has been determined and determineFundingSuccess() can no longer be called
    bool fundingSuccessDetermined;
    // A mapping of token ID to price paid for the token
    mapping(uint256 => uint256) pricePaid;
    // ============ SOULBINDING ============
    // Used to allow an admin to transfer soulbound tokens when necessary
    bool soulboundAdminTransferInProgress;
    // ============ BURN TO MINT ============
    // Maps a token id to the burn token id that was used to mint it to match metadata
    mapping(uint256 => uint256) tokenIdToBurnTokenId;
    // ============ STAKING ============
    // Used to allow direct transfers of staked tokens without unstaking first
    bool stakingTransferActive;
    // Returns the UNIX timestamp at which a token began staking if currently staked
    mapping(uint256 => uint256) currentTimeStaked;
    // Returns the total time a token has been staked in seconds, not counting the current staking time if any
    mapping(uint256 => uint256) totalTimeStaked;
    // ============ LOANING ============
    // Used to keep track of the total number of tokens on loan
    uint256 currentLoanTotal;
    // Returns the total number of tokens loaned by an address
    mapping(address => uint256) totalLoanedPerAddress;
    // Returns the address of the original token owner if a token is currently on loan
    mapping(uint256 => address) tokenOwnersOnLoan;
    // ============ FREE CLAIM ============
    // If true token has already been used to claim and cannot be used again
    mapping(uint256 => bool) freeClaimUsed;
    // ============ RANDOM HASH ============
    // Stores a random hash for each token ID
    mapping(uint256 => bytes32) randomHashStore;
}

library HeyMintStorage {
    struct State {
        BaseConfig cfg;
        AdvancedConfig advCfg;
        BurnToken[] burnTokens;
        Data data;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("heymint.launchpad.storage.erc721a");

    function state() internal pure returns (State storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}