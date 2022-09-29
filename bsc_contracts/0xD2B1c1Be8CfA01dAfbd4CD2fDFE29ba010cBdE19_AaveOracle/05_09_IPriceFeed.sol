// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPriceFeed {

    // --- Function ---
    function fetchPrice() external view returns (uint);
    function updatePrice() external returns (uint);
}