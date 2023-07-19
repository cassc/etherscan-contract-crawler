// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";

contract DogsofDoom is ERC721A {
    constructor() ERC721A("Dogs of Doom", "DOOM") {}

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return "ipfs://QmfUBUG6Leu3xFLY8DFemXs55G6BdxPc5pnzYSJ7GLLSRg/";
    }
}