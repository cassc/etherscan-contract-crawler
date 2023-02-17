// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

/**************************************

    Vested Allocation interface

 **************************************/

abstract contract IVestedAlloc {

    // enums
    enum ReserveType {
        PRESALE_PRIVATE, // populate + claim
        PRESALE_COMMUNITY, // fetch + claim
        AIRDROP, // fetch + claim
        STAKING, // forward -> pool
        DEX, // forward -> admin
        TREASURY, // forward -> pool
        TEAM, // populate + claim
        ADVISORS, // populate + claim
        PARTNERS // populate + claim || forward -> treasury
    }
    enum ReleaseType {
        TIMESTAMP,
        PRICE
    }

    // structs: low level
    struct Release {
        ReleaseType releaseType;
        uint256 requirement; // @dev value based on release type (timestamp or price)
        uint256 amount;
    }
    struct Recipient {
        address owner;
        uint256 share;
    }

    // structs: containers
    struct Allocation {
        uint256 totalReserve;
        Release[] releases;
    }

    // structs: requests
    struct AllocationRequest {
        ReserveType reserveType;
        Allocation allocation;
    }

    struct Shareholder {
        uint256 shares; // applies to all shareholders
        uint256 claimed; // applies to shareholders who already claimed some tokens
        bool isCompromised; // applies to shareholders with team vesting
    }
    
    // structs: storage
    struct VestedReserve {
        Allocation allocation;
        mapping (address => Shareholder) shareholders;
        mapping (uint8 => bool) unlocked; // @dev Used to track price-based ReleaseType
    }

    // events
    event RecipientsAdded(ReserveType reserveType, Recipient[] recipients);
    event DexPoolSet(address sender, address[2] poolPath, address[3] tokenPath);
    event Forwarded(ReserveType reserveType, address forwarder, address shareholder, uint256 amount);
    event Claimed(ReserveType reserveType, address shareholder, uint256 amount);
    event Safeguarded(address forwarder, address shareholder, uint256 amount);
    event ShareholderCompromised(address shareholder);

    // errors
    error InvalidAllocation(AllocationRequest[9] allocation); // FIXME: Hard-coding of ALL_RESERVES
    error InvalidReleaseType(Release release, uint8 ordering);
    error SumNotEqualSupply(uint256 sum, uint256 supply);
    error InvalidRecipientSum(ReserveType reserveType, uint256 sum); // 0x5fc4d0d8
    error InvalidTokens(uint256 balance, uint256 supply); // 0x9fe0a320
    error CannotForwardClaimableFunds(ReserveType reserveType, address recipient);
    error NothingToForward(ReserveType reserveType, address shareholder);
    error NothingToClaim(ReserveType reserveType, address shareholder);
    error NotAllowedToClaim(address shareholder);
    error NothingToSafeguard(address shareholder);
    error ShareholderIsNotCompromised(address shareholder);
    error PriceNotMet(uint256 lastAvg4Hours, uint256 requirement);
    error DexPathsNotSet();
    error CannotTransferThol();
    error UnlockedLessThanClaimed(uint256 unlocked, uint256 claimed, uint256 sum);
    error WrongShareholder(address shareholder);

    /**************************************

         Abstract functions

     **************************************/

    // Unlock Reserve
    function unlockReserve(ReserveType _reserveType, uint8 _releaseNo) external virtual;


    // Thol to USDT conversion
    function tholToUsdt() public virtual view returns (uint256);

}