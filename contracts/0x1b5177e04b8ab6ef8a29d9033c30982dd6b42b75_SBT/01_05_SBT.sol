// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: separate but together
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                      ______            //
//                _____(      )__         //
//            ___(         ⚡️     )___    //
//        ___(         separate      )    //
//       (           but            _)    //
//      (_     together         __))      //
//        ((      ⚡️         _____)       //
//          (_________)----'              //
//             _/  /   \  \_              //
//            /  _/     \_  \             //
//          _/  /         \  \_           //
//         / __/           \__ \          //
//       _/ /                 \ \_        //
//      /__/                   \__\       //
//     //                         \\      //
//    /'                           '\     //
//                                        //
//                                        //
////////////////////////////////////////////


contract SBT is ERC721Creator {
    constructor() ERC721Creator("separate but together", "SBT") {}
}