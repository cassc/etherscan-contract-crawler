// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract ClaimTracker {
    mapping(uint256 => uint256) public claimed;

    function _attempSetClaimed(uint256 index_) internal returns (bool) {
        uint256 claimedWordIndex = index_ / 256;
        uint256 claimedBitIndex = index_ % 256;

        uint256 claimedWord = claimed[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        bool isClaimed = claimedWord & mask == mask;
        if (isClaimed) return false;

        claimed[claimedWordIndex] =
            claimed[claimedWordIndex] |
            (1 << claimedBitIndex);
        return true;
    }
}