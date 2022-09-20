// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721FactionProxy is ERC721 {
    constructor() ERC721("ERC721FactionProxy", "BBFP") {}

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return 1; // Always return balance
    }
}