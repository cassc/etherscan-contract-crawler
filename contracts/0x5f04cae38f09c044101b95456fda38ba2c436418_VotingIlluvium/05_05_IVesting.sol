// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @param balance total underlying balance
/// @param unlocked underlying value already unlocked
/// @param rate value unlocked per second, up to ~1.84e19 tokens per second
/// @param start when position starts unlocking
/// @param end when position unlocking ends
/// @param pendingRevDis pending revenue distribution share to be claimed
/// @param revDisPerTokenPaid last revDisPerToken applied to the position
struct Position {
    uint128 balance;
    uint128 unlocked;
    uint64 start;
    uint64 end;
    uint128 rate;
    uint128 pendingRevDis;
    uint256 revDisPerTokenPaid;
}

interface IVesting {
    /// @notice Returns locked token holders vesting positions
    /// @param _tokenId position nft identifier
    /// @return position the vesting position stored data
    function positions(uint256 _tokenId)
        external
        view
        returns (Position memory);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}