// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: ChubbyDoodles
// contract by: buildship.xyz

import "./ERC721Community.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//       ___  _             _      _                //
//      / __\| |__   _   _ | |__  | |__   _   _     //
//     / /   | '_ \ | | | || '_ \ | '_ \ | | | |    //
//    / /___ | | | || |_| || |_) || |_) || |_| |    //
//    \____/ |_| |_| \__,_||_.__/ |_.__/  \__, |    //
//                                        |___/     //
//        ___                    _  _                //
//       /   \  ___    ___    __| || |  ___  ___     //
//      / /\ / / _ \  / _ \  / _` || | / _ \/ __|    //
//     / /_// | (_) || (_) || (_| || ||  __/\__ \    //
//    /___,'   \___/  \___/  \__,_||_| \___||___/    //
//                                                   //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////

contract ChubbyDoodles is ERC721Community {
    constructor() ERC721Community("ChubbyDoodles", "CD", 5999, 3, START_FROM_ONE, "ipfs://bafybeihs6joxt2jmdea5uxf4w53ghixqwepz5rf5tr5qomyzyrydzdk67y/",
                                  MintConfig(0.001 ether, 10, 50, 0, 0x5723AAb896F25a91E5fCD3237F32B2A1FD042359, false, false, false)) {}
}