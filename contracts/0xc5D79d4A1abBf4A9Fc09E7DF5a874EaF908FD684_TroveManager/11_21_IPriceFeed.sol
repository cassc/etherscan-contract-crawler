// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    // --- Function ---
    function fetchPrice() external returns (uint256);
}