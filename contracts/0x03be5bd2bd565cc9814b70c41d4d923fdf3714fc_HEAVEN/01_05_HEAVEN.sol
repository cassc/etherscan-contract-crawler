// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heaven.NET
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    _-_ _,,               ,,                 //
//       -/  )    _         ||     '           //
//      ~||_<    < \, -_-_  ||/\\ \\  _-_      //
//       || \\   /-|| || \\ || || || || \\     //
//       ,/--|| (( || || || || || || ||/       //
//      _--_-'   \/\\ ||-'  \\ |/ \\ \\,/      //
//     (              |/      _/               //
//                    '                        //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract HEAVEN is ERC721Creator {
    constructor() ERC721Creator("Heaven.NET", "HEAVEN") {}
}