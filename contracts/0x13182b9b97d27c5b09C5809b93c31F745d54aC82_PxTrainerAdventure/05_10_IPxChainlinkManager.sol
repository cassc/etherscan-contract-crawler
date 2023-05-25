// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

interface IPxChainlinkManager {
    /// @notice Recovers signer wallet from signature
    /// @dev View function for signature recovering
    /// @param weekNumber Week number for claim
    /// @param claimIndex Claim index for a particular user for a week
    /// @param walletAddress Token owner wallet address
    /// @param signature Signature from signer wallet
    function isSignerVerifiedFromSignature (
        uint256 weekNumber,
        uint256 claimIndex,
        address walletAddress,
        bytes calldata signature
    ) external returns (bool);

    /// @notice Generate random number from Chainlink
    /// @param _weekNumber Number of the week
    /// @return requestId Chainlink requestId
    function generateChainLinkRandomNumbers(uint256 _weekNumber) external returns (uint256 requestId);

    /// @notice Get weekly random numbers for specific week
    /// @param _weekNumber The number of the week
    function getWeeklyRandomNumbers(uint256 _weekNumber) external view returns (uint256[] memory randomNumbers);
}