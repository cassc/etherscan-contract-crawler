// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

interface INoteKeeper {
    /**
     * @notice  Info for market note
     * @dev     Note::payout is sTHEO remaining to be paid
     *          Note::created is the time the Note was created
     *          Note::matured is the timestamp when the Note is redeemable
     *          Note::redeemed is time market was redeemed
     *          Note::marketID is market ID of deposit. uint48 to avoid adding a slot.
     */
    struct Note {
        uint256 payout;
        uint48 created;
        uint48 matured;
        uint48 redeemed;
        uint48 marketID;
        uint48 discount;
        bool autoStake;
    }

    function redeem(address _user, uint256[] memory _indexes) external returns (uint256);

    function redeemAll(address _user) external returns (uint256);

    function pushNote(address to, uint256 index) external;

    function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index)
        external
        view
        returns (
            uint256 payout_,
            uint48 created_,
            uint48 expiry_,
            uint48 timeRemaining_,
            bool matured_,
            uint48 discount_
        );
}