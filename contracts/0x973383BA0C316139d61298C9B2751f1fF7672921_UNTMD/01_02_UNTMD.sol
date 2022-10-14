// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: The Untamed
// contract by: buildship.xyz

import "./ERC721Community.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    ##  ###  ###  ##  #### ##    ##     ##   ##  ### ###  ### ##       //
//    ##   ##    ## ##  # ## ##     ##     ## ##    ##  ##   ##  ##      //
//    ##   ##   # ## #    ##      ## ##   # ### #   ##       ##  ##      //
//    ##   ##   ## ##     ##      ##  ##  ## # ##   ## ##    ##  ##      //
//    ##   ##   ##  ##    ##      ## ###  ##   ##   ##       ##  ##      //
//    ##   ##   ##  ##    ##      ##  ##  ##   ##   ##  ##   ##  ##      //
//     ## ##   ###  ##   ####    ###  ##  ##   ##  ### ###  ### ##       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

contract UNTMD is ERC721Community {
    constructor() ERC721Community("The Untamed", "UNTMD", 6666, 30, START_FROM_ONE, "ipfs://bafybeiarng5hj4nvdm3khtm7dytlrzvqmowjkt5u47zucbpl6mat36kjd4/",
                                  MintConfig(0.00099 ether, 10, 10, 0, 0x5e58cC23d416E737980b059314fa09996970a47a, false, false, false)) {}
}