// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

interface IBaseBridge {
    /* ========== EVENTS ========== */

    event NFTSentToUser(uint256 tokenId, address targetUser, address msgSender);

    /* ======== ADMIN FUNCTIONS ======== */

    function transferStuckNFT(uint256 _tokenId) external;
}