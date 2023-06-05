// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// name: Radials
// contract by: artgene.xyz

import "./Artgene721.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//      ___    _   ___ ___   _   _    ___     //
//     | _ \  /_\ |   \_ _| /_\ | |  / __|    //
//     |   / / _ \| |) | | / _ \| |__\__ \    //
//     |_|_\/_/ \_\___/___/_/ \_\____|___/    //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////

contract Radials is Artgene721 {
    constructor() Artgene721("Radials", "radials", 1420, 20, START_FROM_ONE, "https://metadata.artgene.xyz/api/g/radials/",
                              MintConfig(0.01 ether, 20, 20, 0, 0x9b2Ae89B298881f92b407348Fea77d825358a4cC, false, 0, 0)) {}
}