// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

contract ERC721Ded is ERC721A {
    constructor(string memory name_, string memory symbol_)
        ERC721A(name_, symbol_)
    {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}