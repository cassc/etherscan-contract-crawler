// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ErotemeArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                       )                        //
//     (    (         ( /(   (     )      (       //
//     )\   )(    (   )\()) ))\   (      ))\      //
//    ((_) (()\   )\ (_))/ /((_)  )\  ' /((_)     //
//    | __| ((_) ((_)| |_ (_))  _((_)) (_))       //
//    | _| | '_|/ _ \|  _|/ -_)| '  \()/ -_)      //
//    |___||_|  \___/ \__|\___||_|_|_| \___|      //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ERO is ERC721Creator {
    constructor() ERC721Creator("ErotemeArt", "ERO") {}
}