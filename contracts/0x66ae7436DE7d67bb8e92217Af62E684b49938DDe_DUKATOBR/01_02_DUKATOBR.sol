// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Dukato Bear
// contract by: buildship.xyz

import "./ERC721Community.sol";

////////////////////
//                //
//                //
//    DUKATOBR    //
//                //
//                //
////////////////////

contract DUKATOBR is ERC721Community {
    constructor() ERC721Community("Dukato Bear", "DUKATOBR", 7000, 1, START_FROM_ONE, "ipfs://bafybeihygbl3b3feb6dh5hiqrkq257o3mkl3rufdnylz3rntf35gwuwtoq/",
                                  MintConfig(0.1 ether, 3, 3, 0, 0x41341180712FeC3702141e927BFc84a0055c2D59, false, false, false)) {}
}