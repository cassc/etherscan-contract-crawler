// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../extensions/ERC721Airdroppable.sol";
import "../utils/Terms.sol";

/**
 * @dev This implements an optional extension of {ERC721Airdroppable}
 */
contract TWDDegenerativeStage1B is ERC721Airdroppable, Terms {
    /**
     * @notice TWDDegenerativeStage1B constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721Airdroppable(name, symbol)
    {
        // Set the default termsURI
        termsURI = "ipfs://Qmbv7aLanDrHKgpZHjcuEaVQB5Em6qPGUJK3ydQdtzzuro";

        // Initial maxSupply is 1250
        // Tokens 2001-3250
        _maxSupply = 1250;

        // Initial token base URI
        _baseTokenURI = "https://api.orangecomet.io/collectible-metadata/twd-degenerative-stage-1b/";

        // Initial contract URI
        _contractURI = "https://api.orangecomet.io/collectible-contracts/twd-degenerative-stage-1b/opensea";

        // Initial royalties address
        _royalties = 0xa036041b00540F5CC666a46C320e83277402864e;
    }

    /**
     * @notice Override start token ID with #2001.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 2001;
    }
}