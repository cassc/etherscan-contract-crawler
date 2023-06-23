// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../NFTCollection.sol";

abstract contract NFTCollectionBurnable is NFTCollection {
    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }
}