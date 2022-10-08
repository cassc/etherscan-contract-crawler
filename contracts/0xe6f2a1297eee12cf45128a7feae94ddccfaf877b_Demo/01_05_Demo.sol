// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

contract Demo is Ownable, ERC721A {
    string public baseURI = "";

    constructor() Ownable() ERC721A("demo", "DEMO") {} // solhint-disable-line

    function mint(uint64 amount) external {
        _mint(msg.sender, amount);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }
}