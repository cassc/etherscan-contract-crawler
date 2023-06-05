// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFoundationSecondarySales {
    /// @notice returns a list of royalties recipients and the amount
    /// @param tokenId the token Id to check for
    /// @return all the recipients and their basis points, for tokenId
    function getFees(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}