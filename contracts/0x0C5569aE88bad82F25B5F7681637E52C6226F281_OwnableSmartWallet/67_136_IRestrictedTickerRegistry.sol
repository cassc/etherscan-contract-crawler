// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IRestrictedTickerRegistry {
    /// @notice Function for determining if a ticker is restricted for claiming or not
    function isRestrictedBrandTicker(string calldata _lowerTicker) external view returns (bool);
}