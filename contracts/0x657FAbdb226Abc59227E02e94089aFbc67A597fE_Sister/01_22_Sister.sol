// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Sister
 * Sister - a contract for non-fungible sisters
 */
contract Sister is ERC721Tradable {
    string public SISTER_COLLECTION_NAME = "1,989 Sisters";
    string public SISTER_SYMBOL = "1989-Sisters";

    constructor(
        address proxyRegistryAddress,
        string memory initialCID,
        string memory finalCID,
        uint256 amount,
        uint256 startFrom
    )
        ERC721Tradable(
            SISTER_COLLECTION_NAME,
            SISTER_SYMBOL,
            proxyRegistryAddress,
            initialCID,
            finalCID,
            amount,
            startFrom
        )
    {}

    function baseTokenURI() public view override returns (string memory) {
        return _baseURI();
    }
}