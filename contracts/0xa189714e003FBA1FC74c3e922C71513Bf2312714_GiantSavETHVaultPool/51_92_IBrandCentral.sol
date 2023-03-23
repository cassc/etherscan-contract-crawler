// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IBrandCentral {
    /// @notice Address of the contract managing list of restricted tickers
    function claimAuction() external view returns (address);
}