// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memeplex
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                           ______           //
//                          /\     \          //
//                         /  \     \         //
//                        /    \_____\        //
//                       _\    / ____/_       //
//                      /\ \  / /\     \      //
//                     /  \ \/_/  \     \     //
//                    /    \__/    \_____\    //
//                    \    /  \    /     /    //
//                     \  /    \  /     /     //
//                      \/_____/\/_____/      //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MEME is ERC721Creator {
    constructor() ERC721Creator("Memeplex", "MEME") {}
}