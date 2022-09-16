// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./POAPLibrary.sol";

interface IBadgesVerifier {
    function claimableBadges(
        uint256[] memory genesisMice,
        uint256[] memory babyMice,
        address wallet
    ) external view returns (uint256[] memory);
}