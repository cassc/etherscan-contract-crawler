// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Yasoki
// contract by: buildship.xyz

import "./ERC721Community.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    ##  ##     ##      ## ##    ## ##   ##  ###    ####       //
//    ##  ##      ##    ##   ##  ##   ##  ##  ##      ##        //
//    ##  ##    ## ##   ####     ##   ##  ## ##       ##        //
//     ## ##    ##  ##   #####   ##   ##  ## ##       ##        //
//      ##      ## ###      ###  ##   ##  ## ###      ##        //
//      ##      ##  ##  ##   ##  ##   ##  ##  ##      ##        //
//      ##     ###  ##   ## ##    ## ##   ##  ###    ####       //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////

contract YSI is ERC721Community {
    constructor() ERC721Community("Yasoki", "YSI", 3000, 1, START_FROM_ONE, "ipfs://bafybeidl4vtbcqopass67b6be34vbnt75jmhfgjgddogkke3ivr7ucptyq/",
                                  MintConfig(0.003 ether, 20, 20, 0, 0x48267D0fC6b25984D853E52F18b5BcEb02B44bB7, false, false, false)) {}
}