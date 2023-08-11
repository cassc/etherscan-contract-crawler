// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: SMINEMS
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract BOIZ is ERC721Community {
    constructor() ERC721Community("SMINEMS", "BOIZ", 2222, 125, START_FROM_ONE, "ipfs://bafybeialessorzo3lbzvsyuoq73hwj42a5big77hulbjhn55dy2pkrry64/",
                                  MintConfig(0.01 ether, 10, 10, 0, 0x4110D273dE5a6bE87a2fA514020731805dC32609, false, false, false)) {}
}