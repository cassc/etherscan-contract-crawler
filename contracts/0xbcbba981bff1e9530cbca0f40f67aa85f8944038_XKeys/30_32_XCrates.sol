// #region Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
// #endregion

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract XCrates {
    using SafeCast for uint256;

    enum CrateState {
        None,
        Locked,
        WinnerDrawn,
        Unlocked
    }

    struct XCrate {
        /* Slot 1 - 32 bytes */
        address requiredOwnership; // 20 bytes
        // the expiration time for the winner to open the crate
        // typically it's CLAIM_DEADLINE (i.e. 48hrs) from the winner being drawn
        uint64 expires; // 8 bytes
        uint16 id; // 2 bytes
        uint8 forRound; // 1 byte
        CrateState state; // 1 byte
    }

    // the current crate id
    uint16 public crateId;

    mapping(uint16 crateId => uint16 tokenId) internal crateWinningToken;

    // the released x crates
    mapping(uint16 crateId => XCrate) public crates;

    mapping(uint16 crateId => address winner) public crateWinners;

    // #region events
    event XCreateCreated(
        uint16 indexed crateId,
        uint8 indexed forRound,
        address indexed requiredOwnership
    );

    // #endregion

    // #region internal functions
    function _setupCrate(uint8 forRound, address requiredOwnership) internal {
        // throw if exceeding 2^16-1 crates
        uint16 _crateId = SafeCast.toUint16(crateId + 1);

        // increment the crate id
        crateId = _crateId;

        // create the new crate
        crates[_crateId] = XCrate({
            requiredOwnership: requiredOwnership,
            id: _crateId,
            forRound: forRound,
            state: CrateState.Locked,
            expires: 0
        });

        emit XCreateCreated(_crateId, forRound, requiredOwnership);
    }
    // #endregion

    // #region external functions

    // #endregion
}