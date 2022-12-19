//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Minter is ERC721 {
    constructor() ERC721("Altairian dollar", "AD") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}