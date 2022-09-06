// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./FrontEndRewarder.sol";

import "../Interfaces/IStakedTHEOToken.sol";
import "../Interfaces/IStaking.sol";
import "../Interfaces/ITreasury.sol";
import "../Interfaces/INoteKeeper.sol";

abstract contract NoteKeeper is INoteKeeper, FrontEndRewarder {
    mapping(address => Note[]) public notes; // user deposit data
    mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership
    mapping(address => mapping(uint256 => uint256)) private noteForClaim; // index of staking claim for a user's note

    event TreasuryUpdated(address addr);
    event PushNote(address from, address to, uint256 noteId);
    event PullNote(address from, address to, uint256 noteId);

    IStakedTHEOToken internal immutable sTHEO;
    IStaking internal immutable staking;
    ITreasury internal treasury;

    constructor(
        ITheopetraAuthority _authority,
        IERC20 _theo,
        IStakedTHEOToken _stheo,
        IStaking _staking,
        ITreasury _treasury
    ) FrontEndRewarder(_authority, _theo) {
        sTHEO = _stheo;
        staking = _staking;
        treasury = _treasury;
    }

    // if treasury address changes on authority, update it
    function updateTreasury() external {
        require(
            msg.sender == authority.governor() ||
                msg.sender == authority.guardian() ||
                msg.sender == authority.policy(),
            "Only authorized"
        );
        address treasuryAddress = authority.vault();
        treasury = ITreasury(treasuryAddress);
        emit TreasuryUpdated(treasuryAddress);
    }

    /* ========== ADD ========== */

    /**
     * @notice             adds a new Note for a user, stores the front end & DAO rewards, and mints & stakes payout & rewards
     * @param _user        the user that owns the Note
     * @param _payout      the amount of THEO due to the user
     * @param _expiry      the timestamp when the Note is redeemable
     * @param _marketID    the ID of the market deposited into
     * @param _discount    the discount on the bond (that is, the bond rate, variable). This is a proportion (that is, a percentage in its decimal form), with 9 decimals
     * @return index_      the index of the Note in the user's array
     */
    function addNote(
        address _user,
        uint256 _payout,
        uint48 _expiry,
        uint48 _marketID,
        address _referral,
        uint48 _discount,
        bool _autoStake
    ) internal returns (uint256 index_) {
        // the index of the note is the next in the user's array
        index_ = notes[_user].length;

        // the new note is pushed to the user's array
        notes[_user].push(
            Note({
                payout: _payout,
                created: uint48(block.timestamp),
                matured: _expiry,
                redeemed: 0,
                marketID: _marketID,
                discount: _discount,
                autoStake: _autoStake
            })
        );

        // front end operators can earn rewards by referring users
        uint256 rewards = _giveRewards(_payout, _referral);

        // mint and stake payout
        treasury.mint(address(this), _payout + rewards);

        if (_autoStake) {
            // note that only the payout gets staked (front end rewards are in THEO)
            // Get index for the claim to approve for pushing
            (, uint256 claimIndex) = staking.stake(address(this), _payout, true);
            // approve the user to transfer the staking claim
            staking.pushClaim(_user, claimIndex);

            // Map the index of the user's note to the claimIndex
            noteForClaim[_user][index_] = claimIndex;
        }
    }

    /* ========== REDEEM ========== */

    /**
     * @notice             redeem notes for user
     * @dev                adapted from Olympus V2. Olympus V2 either sends payout as gOHM
     *                     or calls an `unwrap` function on the staking contract
     *                     to convert the payout from gOHM into sOHM and then send as sOHM.
     *                     This current contract sends payout as sTHEO.
     * @param _user        the user to redeem for
     * @param _indexes     the note indexes to redeem
     * @return payout_     sum of payout sent, in sTHEO
     */
    function redeem(address _user, uint256[] memory _indexes) public override returns (uint256 payout_) {
        uint48 time = uint48(block.timestamp);
        uint256 sTheoPayout = 0;
        uint256 theoPayout = 0;

        for (uint256 i = 0; i < _indexes.length; i++) {
            (uint256 pay, , , , bool matured, ) = pendingFor(_user, _indexes[i]);

            if (matured) {
                notes[_user][_indexes[i]].redeemed = time; // mark as redeemed
                payout_ += pay;
                if (notes[_user][_indexes[i]].autoStake) {
                    uint256 _claimIndex = noteForClaim[_user][_indexes[i]];
                    staking.pushClaimForBond(_user, _claimIndex);
                    sTheoPayout += pay;
                } else {
                    theoPayout += pay;
                }
            }
        }
        if (theoPayout > 0) theo.transfer(_user, theoPayout);
        if (sTheoPayout > 0) sTHEO.transfer(_user, sTheoPayout);
    }

    /**
     * @notice             redeem all redeemable markets for user
     * @dev                if possible, query indexesFor() off-chain and input in redeem() to save gas
     * @param _user        user to redeem all notes for
     * @return             sum of payout sent, in sTHEO
     */
    function redeemAll(address _user) external override returns (uint256) {
        return redeem(_user, indexesFor(_user));
    }

    /* ========== TRANSFER ========== */

    /**
     * @notice             approve an address to transfer a note
     * @param _to          address to approve note transfer for
     * @param _index       index of note to approve transfer for
     */
    function pushNote(address _to, uint256 _index) external override {
        require(notes[msg.sender][_index].created != 0, "Depository: note not found");
        noteTransfers[msg.sender][_index] = _to;

        emit PushNote(msg.sender, _to, _index);
    }

    /**
     * @notice             transfer a note that has been approved by an address
     * @dev                if the note being pulled is autostaked then update noteForClaim as follows:
     *                     get the relevant `claimIndex` associated with the note that is being pulled.
     *                     Then add the claimIndex to the recipient's noteForClaim.
     *                     After updating noteForClaim, the staking claim is pushed to the recipient, in order to
     *                     update `claimTransfers` in the Staking contract and thereby change claim ownership (from the note's pusher to the note's recipient)
     * @param _from        the address that approved the note transfer
     * @param _index       the index of the note to transfer (in the sender's array)
     */
    function pullNote(address _from, uint256 _index) external override returns (uint256 newIndex_) {
        require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
        require(notes[_from][_index].redeemed == 0, "Depository: note redeemed");

        newIndex_ = notes[msg.sender].length;

        if (notes[_from][_index].autoStake) {
            uint256 claimIndex = noteForClaim[_from][_index];
            noteForClaim[msg.sender][newIndex_] = claimIndex;
            staking.pushClaim(msg.sender, claimIndex);
        }
        notes[msg.sender].push(notes[_from][_index]);

        delete notes[_from][_index];
        emit PullNote(_from, msg.sender, _index);
    }

    /* ========== VIEW ========== */

    // Note info

    /**
     * @notice             all pending notes for user
     * @param _user        the user to query notes for
     * @return             the pending notes for the user
     */
    function indexesFor(address _user) public view override returns (uint256[] memory) {
        Note[] memory info = notes[_user];

        uint256 length;
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0 && info[i].payout != 0) length++;
        }

        uint256[] memory indexes = new uint256[](length);
        uint256 position;

        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0 && info[i].payout != 0) {
                indexes[position] = i;
                position++;
            }
        }

        return indexes;
    }

    /**
     * @notice                  calculate amount available for claim for a single note
     * @param _user             the user that the note belongs to
     * @param _index            the index of the note in the user's array
     * @return payout_          the payout due, in sTHEO
     * @return created_         the time the note was created
     * @return expiry_          the time the note is redeemable
     * @return timeRemaining_   the time remaining until the note is matured
     * @return matured_         if the payout can be redeemed
     */
    function pendingFor(address _user, uint256 _index)
        public
        view
        override
        returns (
            uint256 payout_,
            uint48 created_,
            uint48 expiry_,
            uint48 timeRemaining_,
            bool matured_,
            uint48 discount_
        )
    {
        Note memory note = notes[_user][_index];

        payout_ = note.payout;
        created_ = note.created;
        expiry_ = note.matured;
        timeRemaining_ = note.matured > block.timestamp ? uint48(note.matured - block.timestamp) : 0;
        matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
        discount_ = note.discount;
    }

    function getNotesCount(address _user) external view returns (uint256) {
        return notes[_user].length;
    }
}