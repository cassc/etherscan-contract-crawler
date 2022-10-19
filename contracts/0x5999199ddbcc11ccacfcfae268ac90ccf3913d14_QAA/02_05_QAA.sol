// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Questions and answers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//       ____  _      _       //
//      /___ \/_\    /_\      //
//     //  / //_\\  //_\\     //
//    / \_/ /  _  \/  _  \    //
//    \___,_\_/ \_/\_/ \_/    //
//                            //
//                            //
//                            //
//                            //
//                            //
////////////////////////////////


contract QAA is ERC721Creator {
    constructor() ERC721Creator("Questions and answers", "QAA") {}
}