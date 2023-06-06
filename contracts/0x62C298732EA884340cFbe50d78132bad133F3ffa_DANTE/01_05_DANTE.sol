// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: inferno
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//               (                                //
//     (         )\ )    (   (                    //
//     )\   (   (()/(   ))\  )(    (      (       //
//    ((_)  )\ ) /(_)) /((_)(()\   )\ )   )\      //
//     (_) _(_/((_) _|(_))   ((_) _(_/(  ((_)     //
//     | || ' \))|  _|/ -_) | '_|| ' \))/ _ \     //
//     |_||_||_| |_|  \___| |_|  |_||_| \___/     //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract DANTE is ERC721Creator {
    constructor() ERC721Creator("inferno", "DANTE") {}
}