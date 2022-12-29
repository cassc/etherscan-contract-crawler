// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Llamily Christmas
/// @author: manifold.xyz

import "./02_05_ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//    .____   __________.____         //
//    |    |  \______   \    |        //
//    |    |   |    |  _/    |        //
//    |    |___|    |   \    |___     //
//    |_______ \______  /_______ \    //
//            \/      \/        \/    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract LBLXMAS is ERC721Creator {
    constructor() ERC721Creator("A Llamily Christmas", "LBLXMAS") {}
}