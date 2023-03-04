// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SottiKotti FanFic Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//      _________       __    __  .__ ____  __.      __    __  .__     //
//     /   _____/ _____/  |__/  |_|__|    |/ _|_____/  |__/  |_|__|    //
//     \_____  \ /  _ \   __\   __\  |      < /  _ \   __\   __\  |    //
//     /        (  <_> )  |  |  | |  |    |  (  <_> )  |  |  | |  |    //
//    /_______  /\____/|__|  |__| |__|____|__ \____/|__|  |__| |__|    //
//            \/                             \/                        //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract sottikottifanficcollection is ERC721Creator {
    constructor() ERC721Creator("SottiKotti FanFic Collection", "sottikottifanficcollection") {}
}