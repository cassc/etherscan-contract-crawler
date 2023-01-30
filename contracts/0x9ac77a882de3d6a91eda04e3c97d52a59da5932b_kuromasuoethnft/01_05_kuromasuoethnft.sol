// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kuromasuo.eth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    __                                                                //
//    |  | ____ _________  ____   _____ _____    ________ __  ____      //
//    |  |/ /  |  \_  __ \/  _ \ /     \\__  \  /  ___/  |  \/  _ \     //
//    |    <|  |  /|  | \(  <_> )  Y Y  \/ __ \_\___ \|  |  (  <_> )    //
//    |__|_ \____/ |__|   \____/|__|_|  (____  /____  >____/ \____/     //
//         \/                         \/     \/     \/                  //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract kuromasuoethnft is ERC721Creator {
    constructor() ERC721Creator("kuromasuo.eth", "kuromasuoethnft") {}
}