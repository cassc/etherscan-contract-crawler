// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: SwordsManMeta
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SwordsMan is ERC721Community {
    constructor() ERC721Community("SwordsManMeta", "SwordsMan", 6600, 500, START_FROM_ONE, "ipfs://QmYfAF82vfGNFpTnCncYhBLVB5byAvwfsMFR9jRJtgpAzU/",
                                  MintConfig(0.03 ether, 5, 30, 0, 0x3B4b3b034C2d3C661CaeE198acc2b6b163B68bd9, false, false, true)) {}
}