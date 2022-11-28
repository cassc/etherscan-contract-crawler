// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract VoltronGobblerStorageV1 {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public artGobblers;
    address public goo;
    address public goober;

    /*//////////////////////////////////////////////////////////////
                                USER DATA
    //////////////////////////////////////////////////////////////*/

    // gobblerId => user
    mapping(uint256 => address) public getUserByGobblerId;

    /// @notice Struct holding data relevant to each user's account.
    struct UserData {
        // The total number of gobblers currently owned by the user.
        uint32 gobblersOwned;
        // The sum of the multiples of all gobblers the user holds.
        uint32 emissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 virtualBalance;
        // claimed pool's gobbler number
        uint16 claimedNum;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
        // Timestamp of the last goo deposit.
        uint48 lastGooDepositedTimestamp;
    }

    /// @notice Maps user addresses to their account data.
    mapping(address => UserData) public getUserData;

    /*//////////////////////////////////////////////////////////////
                                POOL DATA
    //////////////////////////////////////////////////////////////*/

    struct GlobalData {
        // The total number of gobblers currently deposited by the user.
        uint32 totalGobblersDeposited;
        // The sum of the multiples of all gobblers the user holds.
        uint32 totalEmissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 totalVirtualBalance;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
    }

    GlobalData public globalData;

    /// @notice Maps gobbler IDs to claimable
    mapping(uint256 => bool) public gobblerClaimable;
    uint256[] public claimableGobblers;
    uint256 public claimableGobblersNum;

    /*//////////////////////////////////////////////////////////////
                                admin
    //////////////////////////////////////////////////////////////*/

    bool public mintLock;
    bool public claimGobblerLock;

    // must stake timeLockDuration time to withdraw
    // Avoid directly claiming the cheaper gobbler after the user deposits goo
    uint256 public timeLockDuration;

    // a privileged address with the ability to mint gobblers
    address public minter;
}