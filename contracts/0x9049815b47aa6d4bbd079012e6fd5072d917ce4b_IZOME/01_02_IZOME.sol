// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Izometria
// contract by: buildship.xyz

import "./ERC721Community.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//      ####   ### ##    ## ##   ##   ##  ### ###  #### ##  ### ##     ####     ##         //
//       ##    ##  ##   ##   ##   ## ##    ##  ##  # ## ##   ##  ##     ##       ##        //
//       ##       ##    ##   ##  # ### #   ##        ##      ##  ##     ##     ## ##       //
//       ##      ##     ##   ##  ## # ##   ## ##     ##      ## ##      ##     ##  ##      //
//       ##     ##      ##   ##  ##   ##   ##        ##      ## ##      ##     ## ###      //
//       ##    ##  ##   ##   ##  ##   ##   ##  ##    ##      ##  ##     ##     ##  ##      //
//      ####   # ####    ## ##   ##   ##  ### ###   ####    #### ##    ####   ###  ##      //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////

contract IZOME is ERC721Community {
    constructor() ERC721Community("Izometria", "IZOME", 3333, 3, START_FROM_ONE, "ipfs://bafybeibk5zbun7zvptjzneejvakojv22iy54bzio3ovz44bntozrr6bpvm/",
                                  MintConfig(0.006 ether, 5, 5, 0, 0x5D839f1D871F55410FCf462B8A772275bA0d929A, false, false, false)) {}
}