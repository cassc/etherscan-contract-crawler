// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Mutant Hound Peg Collars
// contract by: buildship.xyz

import "./ERC721Community.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     /$      /$ /$   /$ /$$$$   /$$$     //
//    | $$    /$$| $  | $| $__  $ /$__  $    //
//    | $$  /$$| $  | $| $  \ $| $  \__/    //
//    | $ $/$ $| $$$$| $$$$/| $          //
//    | $  $$| $| $__  $| $____/ | $          //
//    | $\  $ | $| $  | $| $      | $    $    //
//    | $ \/  | $| $  | $| $      |  $$$/    //
//    |__/     |__/|__/  |__/|__/       \______/     //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////

contract MHPC is ERC721Community {
    constructor() ERC721Community("Mutant Hound Peg Collars", "MHPC", 10000, 1000, START_FROM_ONE, "ipfs://bafybeiflrfgdaly5aae7adccyrhxutzkrklo4bvmpc6cbwxu7d5iiy34pm/",
                                  MintConfig(0.0005 ether, 15, 15, 0, 0x7bDB65a589AbA1584071Bc09Ad39289aF432Cb1E, false, false, false)) {}
}