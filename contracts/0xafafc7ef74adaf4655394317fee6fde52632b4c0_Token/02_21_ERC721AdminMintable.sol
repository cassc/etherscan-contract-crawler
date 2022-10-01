// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/AdminControlled.sol";
import "./ERC721Base.sol";

abstract contract ERC721AdminMintable is ERC721Base, AdminControlled {
    /**
     * @notice Allows admin to "airdrop" NFTs to a large audience
     * @param accounts The list of recipient addresses
     * @param tokenIDs The list of token IDs to be airdropped
     */
    function adminBatchMint(address[] memory accounts, uint256[] memory tokenIDs) external onlyAdminAddress {
        uint256 len = accounts.length;

        require(len == tokenIDs.length, "LENGTH_MISMATCH");
        require(totalSupply() + len <= totalMaxSupply, "Max supply exceeded");

        // For each of the provided addresses - mint nft
        for (uint256 i = 0; i < len; ) {
            _mint(accounts[i], tokenIDs[i]);

            unchecked {
                ++i;
            }
        }
    }
}