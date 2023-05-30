// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

contract ClaimBitmap {
    uint256[] public claimedBitmap;

    /**
     * Cannot reallocate memory if initialized
     */
    error BitmapAlreadyInitialized();

    /**
     * @notice emitted when an account has claimed a token id
     */
    event ClaimedForTokenId(uint256 indexed tokenId);

    /**
     * @notice initialize the claim bitmap array
     * @param maximumTokens the maximum amount of tokens
     */
    function _initializeBitmap(uint256 maximumTokens) internal {
        if (claimedBitmap.length != 0) revert BitmapAlreadyInitialized();

        uint256 bitMapSize = Math.ceilDiv(maximumTokens, 256);
        claimedBitmap = new uint256[](bitMapSize);
    }

    /**
     * @notice checks to see if a token id has been claimed
     * @param tokenId the token id
     */
    function isClaimed(uint256 tokenId) public view returns (bool) {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        uint256 claimedWord = claimedBitmap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    /**
     * @notice sets the token id as claimed
     * @param tokenId the token id
     */
    function _setClaimed(uint256 tokenId) internal {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        claimedBitmap[claimedWordIndex] = claimedBitmap[claimedWordIndex] | (1 << claimedBitIndex);

        emit ClaimedForTokenId(tokenId);
    }
}