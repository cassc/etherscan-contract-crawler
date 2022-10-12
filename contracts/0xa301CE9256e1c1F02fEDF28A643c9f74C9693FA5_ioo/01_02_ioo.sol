// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: ooki
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract ioo is ERC721Community {
    constructor() ERC721Community("ooki", "ioo", 700, 1, START_FROM_ONE, "ipfs://bafybeidgkgoa66pyrf3brsgrlt5ur6ycja743et2t2hgtgjjyuz7memaza/",
                                  MintConfig(0.1 ether, 3, 3, 0, 0xe953cb4c1BD71376e8b5Ad1885808bDF40df667F, false, false, false)) {}
}