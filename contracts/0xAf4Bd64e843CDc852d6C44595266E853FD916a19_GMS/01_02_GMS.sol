// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: 35GMs

import "./ERC721Community.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     ,adPPYb,d8 88,dPYba,,adPYba,       //
//    a8"    `Y88 88P'   "88"    "8a      //
//    8b       88 88      88      88      //
//    "8a,   ,d88 88      88      88      //
//     `"YbbdP"Y8 88      88      88      //
//     aa,    ,88                         //
//      "Y8bbdP"         //
//        //
//    35GMs by @jamesrichardfry    //
//                                        //
//                                        //
////////////////////////////////////////////

contract GMS is ERC721Community {
    constructor() ERC721Community("35GMs", "GMS", 353, 10, START_FROM_ONE, "ipfs://bafybeic5ny5puw3urjqvyvj5v5wldbemm5ojkwsrlpoe2ckbjlnxjr7coi/",
                                  MintConfig(0.0035 ether, 3, 3, 0, 0x16e6F2B9d07b929F58355778887733677e765337, false, false, false)) {}
}