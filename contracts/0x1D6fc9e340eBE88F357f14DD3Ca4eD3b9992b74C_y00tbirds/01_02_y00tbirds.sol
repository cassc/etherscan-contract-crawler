// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: y00tbirds
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract y00tbirds is ERC721Community {
    constructor() ERC721Community("y00tbirds", "YB", 10000, 50, START_FROM_ONE, "ipfs://bafybeibvmp2hhkolei3z5gcneu44j7wgvmvtkarmki7kgc6r625gnhmtbi/",
                                  MintConfig(0.002 ether, 20, 20, 0, 0x1beb06e99fBa9702207D46aD4c5b217860B7d975, false, false, false)) {}
}