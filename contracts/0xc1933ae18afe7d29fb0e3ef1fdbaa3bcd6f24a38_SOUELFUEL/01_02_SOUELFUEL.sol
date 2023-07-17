// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: SoulFuel
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SOUELFUEL is ERC721Community {
    constructor() ERC721Community("SoulFuel", "SOUELFUEL", 80, 10, START_FROM_ONE, "ipfs://bafybeif5o53nsgvd72dexa42wjwyezjy5vkh72zqjxtgrru7y4qlbmq7bq/",
                                  MintConfig(2.75 ether, 50, 50, 0, 0x65b6EdF84513eeA3dAB261FC02DCa41Bd862d266, false, false, false)) {}
}