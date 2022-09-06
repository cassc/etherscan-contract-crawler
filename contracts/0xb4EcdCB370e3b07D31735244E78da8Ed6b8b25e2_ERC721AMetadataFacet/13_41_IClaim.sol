//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice represents a claim on some deposit.
struct Claim {
    // claim id.
    uint256 id;
    address feeRecipient;
    // pool address
    address mineAddress;
    // the amount of eth deposited
    uint256 depositAmount;
    // the gem quantity to mint to the user upon maturity
    uint256 mintQuantity;
    // the deposit length of time, in seconds
    uint256 depositLength;
    // the block number when this record was created.
    uint256 createdTime;
    // the block number when this record was created.
    uint256 createdBlock;
    // block number when the claim was submitted or 0 if unclaimed
    uint256 claimedBlock;
    // the fee that was paid
    uint256 feePaid;
    // whether this claim has been collected
    bool collected;
    // whether this claim must be mature before it can be collected
    bool requireMature;
    // whether this claim has been collected
    bool mature;
}

/// @notice a set of requirements. used for random access
struct ClaimSet {
    mapping(uint256 => uint256) keyPointers;
    uint256[] keyList;
    Claim[] valueList;
}

struct ClaimSettings {
    ClaimSet claims;
    // the total staked for each token type (0 for ETH)
    mapping(address => uint256) stakedTotal;
}

struct ClaimContract {
    uint256 gemsMintedCount;  // total number of gems minted
    uint256 totalStakedEth; // total amount of staked eth
    mapping(uint256 => Claim) claims;  // claim data
    // staked total and claim index
    uint256 stakedTotal;
    uint256 claimIndex;
}

/// @notice interface for a collection of tokens. lists members of collection, allows for querying of collection members, and for minting and burning of tokens.
interface IClaim {
    /// @notice emitted when a token is added to the collection
    event ClaimCreated(
        address indexed user,
        address indexed minter,
        Claim claim
    );

    /// @notice emitted when a token is removed from the collection
    event ClaimRedeemed(
        address indexed user,
        address indexed minter,
        Claim claim
    );

    /// @notice create a claim
    /// @param _claim the claim to create
    /// @return _claimHash the claim hash
    function createClaim(Claim memory _claim)
        external
        payable
        returns (Claim memory _claimHash);

    /// @notice submit claim for collection
    /// @param claimHash the id of the claim
    function collectClaim(uint256 claimHash, bool requireMature) external;

    /// @notice return the next claim hash
    /// @return _nextHash the next claim hash
    function nextClaimHash() external view returns (uint256 _nextHash);

    /// @notice get all the claims
    /// @return _claims all the claims
    function claims() external view returns (Claim[] memory _claims);
}