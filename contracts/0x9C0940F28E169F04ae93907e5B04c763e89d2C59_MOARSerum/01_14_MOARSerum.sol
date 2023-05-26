// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./fwen/FWEN1155.sol";

error ArrayLengthMismatch();

contract MOARSerum is FWEN1155 {
    // NFT name
    string constant public name = "MOAR Serum";

    // NFT symbol
    string constant public symbol = "MOARSerum";

    /**
     * @dev Constructor function.
     * @param admin_ admin role
     * @param royaltyAddress royalty fee receiver address
     */
    constructor(address admin_, address royaltyAddress) FWEN1155(admin_, royaltyAddress) {
        _baseURI = "https://assets.thefwenclub.com/moar-serum/";
    }

    /**
     * @dev Creates `amount` of new tokens for every address in `tos`, tokenId will be `id`.
     * @param tos owners of new tokens
     * @param id tokenId of new tokens
     * @param amounts amount of new token to create for each new owner
     *
     * Requirements:
     *
     * - the caller must be `minter`.
     */
    function airdrop(address[] memory tos,uint256 id, uint256[] memory amounts) external onlyMinter {
        if (tos.length != amounts.length) { revert ArrayLengthMismatch(); }
        for (uint256 i = 0; i < tos.length; i++) {
            _mint(tos[i], id, amounts[i], "");
        }
    }
}