// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../extensions/ERC721Airdroppable.sol";
import "../utils/Terms.sol";

/**
 * @dev This implements an optional extension of {ERC721Airdroppable}
 */
contract TWDDegenerativeStage4 is ERC721Airdroppable, Terms {
    /**
     * @notice TWDDegenerativeStage4 constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721Airdroppable(name, symbol)
    {
        // Set the default termsURI
        termsURI = "ipfs://Qmbv7aLanDrHKgpZHjcuEaVQB5Em6qPGUJK3ydQdtzzuro";

        // Initial maxSupply is 2000
        _maxSupply = 2000;

        // Initial token base URI
        _baseTokenURI = "https://api.orangecomet.io/collectible-metadata/twd-degenerative-stage-4/";

        // Initial contract URI
        _contractURI = "https://api.orangecomet.io/collectible-contracts/twd-degenerative-stage-4/opensea";
    }
}