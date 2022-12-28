// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: CatsClub
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract CC is ERC721Community {
    constructor() ERC721Community("CatsClub", "CC", 10, 1, START_FROM_ONE, "ipfs://bafybeigjtw27uc45jgzcuqwygjodpwg2zihpqlvvie2s7ga5wbybayavpm/",
                                  MintConfig(1 ether, 3, 3, 0, 0xe29Eb657deff60bf063d6177f8A71F7035dE8e95, false, false, false)) {}
}