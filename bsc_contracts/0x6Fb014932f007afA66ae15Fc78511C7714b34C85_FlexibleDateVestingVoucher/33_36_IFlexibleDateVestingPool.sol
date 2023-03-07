// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IFlexibleDateVestingPool {

    struct SlotDetail {
        address issuer;
        uint8 claimType;
        uint64 startTime;
        uint64 latestStartTime;
        uint64[] terms;
        uint32[] percentages;
        bool isValid;
    }

    /** ===== Begin of events emited by FlexibleDateVestingPool ===== */
    event NewManager(address oldManager, address newManager);

    event NewGovernor(address oldGovernor, address newGovernor);

    event CreateSlot (
        uint256 indexed slot,
        address indexed issuer,
        uint8 claimType,
        uint64 latestStartTime,
        uint64[] terms,
        uint32[] percentages
    );

    event Mint (
        address indexed minter,
        uint256 indexed slot,
        uint256 vestingAmount
    );

    event Claim (
        uint256 indexed slot,
        address indexed claimer,
        uint256 claimAmount
    );

    event SetStartTime (
        uint256 indexed slot,
        uint64 oldStartTime,
        uint64 newStartTime
    );

    event SetDelayTime (
        uint256 indexed slot, 
        uint64 oldDelayTime,
        uint64 newDelayTime
    );
    /** ===== End of events emited by FlexibleDateVestingPool ===== */

}