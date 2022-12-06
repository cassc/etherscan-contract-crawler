// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

import "erc721a/contracts/IERC721A.sol";

interface IERC721SU is IERC721A {
    /// @notice Get the pass level of an NFT
    /// @param _tokenId The NFT to get the pass level for
    /// @return The pass level for this NFT
    function getPassLevel(uint256 _tokenId)
        external
        view
        returns (string memory);
}