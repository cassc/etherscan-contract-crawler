// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IRandomProvider {
    /// @notice Returns whether the request is overdue or not
    /// @param requestId identifier of a request
    /// @return boolean whether the request is overdue or not
    function isRequestOverdue(uint256 requestId) external view returns (bool);

    /// @notice Makes a random number request to the Chainlink VRF Coordinator
    /// @dev the overdue criteria is whether 24 hours passed
    /// @param listingId identifier of a listing
    /// @return requestId identifier of a request
    function requestRandom(uint256 listingId) external returns (uint256);
}