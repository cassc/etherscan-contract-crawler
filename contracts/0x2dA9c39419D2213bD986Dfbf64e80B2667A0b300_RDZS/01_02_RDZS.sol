// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: RugDollz Social
// contract by: buildship.xyz

import "./ERC721Community.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//     #####    ##  ##    ####    ##         ##     #####    ######      //
//     ##  ##   ##  ##   ##  ##   ##        ####    ##  ##       ##      //
//     ##  ##   ##  ##   ##       ##       ##  ##   ##  ##      ##       //
//     #####    ##  ##   ## ###   ##       ######   #####      ##        //
//     ####     ##  ##   ##  ##   ##       ##  ##   ##  ##    ##         //
//     ## ##    ##  ##   ##  ##   ##       ##  ##   ##  ##   ##          //
//     ##  ##    ####     ####    ######   ##  ##   #####    ######      //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

contract RDZS is ERC721Community {
    constructor() ERC721Community("RugDollz Social", "RDZS", 10000, 1000, START_FROM_ONE, "ipfs://bafybeihkktj7jzhuvxnhsh5o32im3oipxjjbukeaa2bs7dw2x2rzoctcry/",
                                  MintConfig(0.1 ether, 1, 3, 0, 0x5373D8b3403A944bDAB547f395CF22Df207adE8b, false, false, false)) {}
}