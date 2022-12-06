// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";

/*
 * @title ERC721ConsecutiveMock
 */
contract ERC721ConsecutiveMock is ERC721A {
    constructor() ERC721A("test", "TEST") {
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return
            string(
                "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/1.json"
            );
    }

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    function mintConsecutive(address to, uint96 amount) public {
        _mintERC2309(to, amount);
    }
}