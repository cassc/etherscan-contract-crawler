// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { ERC721Airdroppable } from "../extensions/ERC721Airdroppable.sol";
import { Terms } from "../utils/Terms.sol";

/**
 * @dev This implements an optional extension of {ERC721Airdroppable}
 */
contract TWDLandsToolsS2 is ERC721Airdroppable, Terms {
    /**
     * @notice TWDLandsToolsS2 constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC721Airdroppable(name, symbol) {
        // Set the default termsURI
        termsURI = "ipfs://Qmbv7aLanDrHKgpZHjcuEaVQB5Em6qPGUJK3ydQdtzzuro";

        // Initial maxSupply is 10000
        // Tokens 14001-24000
        _maxSupply = 10000;

        // Initial token base URI
        _baseTokenURI = "https://api.orangecomet.io/collectible-metadata/twd-lands-series-2/";

        // Initial contract URI
        _contractURI = "https://api.orangecomet.io/collectible-contracts/twd-lands-series-2/opensea";

        // Initial royalties address
        _royalties = 0x09B614300f474DC2F6872f4f1705a17BDF9A6C20;
    }

    /**
     * @notice Override start token ID with #14001.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 14001;
    }
}