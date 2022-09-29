// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: No One Will Feed You In The Jungle
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract NoOneWillFeedYouInTheJungle is ERC721Community {
    constructor() ERC721Community("No One Will Feed You In The Jungle", "JUNG", 333, 1, START_FROM_ONE, "ipfs://bafybeib42qaxwqwsau6our52txytb3aqztv7srhnj2bez6wjom5rkkvcyi/",
                                  MintConfig(0.0045 ether, 3, 3, 0, 0xB1FDf8AD8153Aa641Ea8cf16121C14657ec26649, false, false, false)) {}
}