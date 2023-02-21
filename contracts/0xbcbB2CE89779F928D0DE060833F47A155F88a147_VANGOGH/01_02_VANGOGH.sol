// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Van Gogh Legacy
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract VANGOGH is ERC721Community {
    constructor() ERC721Community("Van Gogh Legacy", "VANGOGH", 1931, 50, START_FROM_ONE, "ipfs://bafybeifyinip5cfzzsv7d4p3xspwzknzjqtxnqnbjsqt67slcibmvhzh5q/",
                                  MintConfig(0.06 ether, 15, 15, 0, 0xd297F990B8E4b3C921dc830F31FCe926CB7742fc, false, false, true)) {}
}