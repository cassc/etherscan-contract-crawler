// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/AdminControlled.sol";
import "./ERC721Base.sol";

abstract contract ERC721AdminBurnable is ERC721Base, AdminControlled {
    /**
     * @notice Allows admin to burn NFTs with the given IDs
     * @param tokenIDs The list of token IDs to be burned
     */
    function adminBatchBurn(uint256[] memory tokenIDs) external onlyAdminAddress {
        uint256 len = tokenIDs.length;

        require(totalSupply() >= len, "No available token to burn");

        for (uint256 i = 0; i < len; ) {
            _burn(tokenIDs[i]);

            unchecked {
                ++i;
            }
        }
    }
}