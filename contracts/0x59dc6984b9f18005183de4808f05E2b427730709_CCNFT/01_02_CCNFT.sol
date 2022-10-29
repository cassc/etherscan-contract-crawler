// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Cool Cowboys
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract CCNFT is ERC721Community {
    constructor() ERC721Community("Cool Cowboys", "CCNFT", 10000, 1000, START_FROM_ONE, "ipfs://bafybeihngenofevdn5izy5vl6yhfnhn6ivtldmckdzozbnpnqduj7wjqwi/",
                                  MintConfig(0.015 ether, 20, 20, 0, 0xa196Dd758a87BE1371f427c9156F89c724b4B4F9, false, false, false)) {}
}