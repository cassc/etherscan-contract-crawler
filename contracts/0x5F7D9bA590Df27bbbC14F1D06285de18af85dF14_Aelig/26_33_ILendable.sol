// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC4907.sol";

interface ILendable is IERC4907 {
    function setUserWithUploads(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    function claimArtwork(
        address to,
        uint256 frameId
    ) external;

    function claimFrame(
        uint256 frameId
    ) external;

    function lendArtwork(
        uint256 lenderId,
        uint256 recipient,
        uint256 expires
    ) external;

    function canBeUpdated(
        uint256 frameId
    )
    view
    external
    returns(bool);
}