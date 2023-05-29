// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../extensions/ERC721Airdroppable.sol";
import "../utils/Terms.sol";

/**
 * @dev This implements an optional extension of {ERC721Airdroppable}
 */
contract TWDDeadLandsDeed is ERC721Airdroppable, Terms {
    /**
     * @notice TWDDeadLandsDeed constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721Airdroppable(name, symbol)
    {
        // Set the default termsURI
        termsURI = "ipfs://Qmbv7aLanDrHKgpZHjcuEaVQB5Em6qPGUJK3ydQdtzzuro";

        // Initial maxSupply is 44950 since 50000 is allocated in the
        // Dead Lands Deed project
        // 5K deeds in 0x4d3709B78b5868cE9AbbF2CAE667FCd23258Bcb8
        // 50 deeds in 0x156Ca3D29445C7a5A3ffED133da4FC73DB1c0091
        _maxSupply = 44950;

        // Initial token base URI
        _baseTokenURI = "https://api.orangecomet.io/collectible-metadata/twd-dead-lands-deed/";

        // Initial contract URI
        _contractURI = "https://api.orangecomet.io/collectible-contracts/twd-dead-lands-deed/opensea";
    }

    /**
     * @notice Override start token ID with #5051.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 5051;
    }
}