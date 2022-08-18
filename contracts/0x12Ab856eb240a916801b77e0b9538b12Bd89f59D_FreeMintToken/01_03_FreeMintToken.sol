// SPDX-License-Identifier: MIT
// Made by @Web3Club

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

contract FreeMintToken is ERC721A {

    uint256 public constant USER_LIMIT = 2;
    uint256 public constant MAX_SUPPLY = 2;

    constructor() ERC721A("AnotherTestaNFTest", "TTKAGA") {}

    function mint(uint256 quantity) external {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Not more supply left");
        require(_numberMinted(msg.sender) + quantity <= USER_LIMIT, "User limit reached");
        // add allowlist verification here
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://Qma9bUGStj1b7WGXY7nsVKSmMEc6vFtU7XtnyVySCt9enM/";
    }
}