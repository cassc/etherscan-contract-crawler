// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../extensions/ERC721Airdroppable.sol";
import "../utils/Terms.sol";

/**
 * @dev This implements an optional extension of {ERC721Airdroppable}
 */
contract TheDescendantsBloodline is ERC721Airdroppable, Terms {
    /**
     * @notice TheDescendantsBloodline constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721Airdroppable(name, symbol)
    {
        // Set the default termsURI
        termsURI = "ipfs://Qmbv7aLanDrHKgpZHjcuEaVQB5Em6qPGUJK3ydQdtzzuro";

        // Initial maxSupply is 2200
        _maxSupply = 2200;

        // Initial token base URI
        _baseTokenURI = "https://api.orangecomet.io/collectible-metadata/the-descendants-bloodline/";

        // Initial contract URI
        _contractURI = "https://api.orangecomet.io/collectible-contracts/the-descendants-bloodline/opensea";

        // Initial royalties address
        _royalties = 0xAd87B6F80686f5c797F89edCbA27F1325aFc2718;
    }
}