// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xCyberia
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//       __ _    ,__   __ _ __    _   __     //
//      /  ' )  //  ) /  ' )  )  | ) /  )    //
//     /    /  //--< /--  /--,---|/ /--/     //
//    (__/ (__//___/(___,/  \_\_/ \/  (_     //
//          //                               //
//         (/                                //
//                                           //
//                                           //
///////////////////////////////////////////////


contract Cyb is ERC1155Creator {
    constructor() ERC1155Creator("0xCyberia", "Cyb") {}
}