// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

abstract contract Claims {
    mapping(uint256 => uint256) private ggClaimedBitmap;

    function ggClaimed(uint256 index) external view returns (bool) {
        return _isClaimed(index);
    }

    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        ggClaimedBitmap[claimedWordIndex] =
            ggClaimedBitmap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function _isClaimed(uint256 index) internal view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = ggClaimedBitmap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
}