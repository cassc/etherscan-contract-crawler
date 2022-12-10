// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Collection is ERC721URIStorage, DefaultOperatorFilterer, Ownable {

    uint256 tokenId = 0;

    constructor() ERC721('Japanese Traditional Music -WAGAKKI-', 'JTM') {}

    function mint(string memory uri) public onlyOwner {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        tokenId++;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}