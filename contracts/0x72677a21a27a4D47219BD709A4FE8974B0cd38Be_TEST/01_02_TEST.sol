// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: PayoutsTest
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract TEST is ERC721Community {
    constructor() ERC721Community("PayoutsTest", "TEST", 1000, 1, START_FROM_ZERO, "ipfs://bafybeiehnwbrjwmpm45nmqggbjvn4gd336nssjrhfid34n6zgifjvufx6a/",
                                  MintConfig(0.1 ether, 3, 3, 0, 0x238bE3BB3aBf5a3Da83048c7816a0EF17a1dC06a, true, false, false)) {}
}