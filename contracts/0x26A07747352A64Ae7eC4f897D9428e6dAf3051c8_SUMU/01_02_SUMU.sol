// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Sumuzu
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SUMU is ERC721Community {
    constructor() ERC721Community("Sumuzu", "SUMU", 8999, 20, START_FROM_ONE, "ipfs://bafybeie647v6fxxlo5bmvbefjjz3qukmwwprfpcfnccprn5uc2b6zoybe4/",
                                  MintConfig(0.06 ether, 5, 5, 0, 0x95045Fc3b89c49c0d8f603162bd72Cc42A831A84, false, false, false)) {}
}