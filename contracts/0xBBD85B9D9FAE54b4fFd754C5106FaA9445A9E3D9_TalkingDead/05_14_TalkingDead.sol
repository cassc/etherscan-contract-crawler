// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "orangecomet-contracts/contracts/extensions/ERC721Auctionable.sol";
import "orangecomet-contracts/contracts/utils/Terms.sol";

contract TalkingDead is ERC721Auctionable, Terms {
    /**
     * @notice TalkingDead constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721Auctionable(name, symbol)
    {
        // set the initial supply of the token
        _maxSupply = 11;

        // Set the default Orange Comet / AMC termsURI
        termsURI = "ipfs://Qmbv7aLanDrHKgpZHjcuEaVQB5Em6qPGUJK3ydQdtzzuro";
    }

    /**
     * @notice Mint the entire collection to the owner in prep for auction
     */
    function mintCollection() public onlyOwner {
        ownerMint(owner(), _maxSupply);
    }
}