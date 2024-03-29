// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hybrid Codes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//          )                                                             //
//       ( /(           )           (        (          (                 //
//       )\()) (     ( /(  (   (    )\ )     )\         )\ )   (          //
//      ((_)\  )\ )  )\()) )(  )\  (()/(   (((_)   (   (()/(  ))\ (       //
//       _((_)(()/( ((_)\ (()\((_)  ((_))  )\___   )\   ((_))/((_))\      //
//      | || | )(_))| |(_) ((_)(_)  _| |  ((/ __| ((_)  _| |(_)) ((_)     //
//      | __ || || || '_ \| '_|| |/ _` |   | (__ / _ \/ _` |/ -_)(_-<     //
//      |_||_| \_, ||_.__/|_|  |_|\__,_|    \___|\___/\__,_|\___|/__/     //
//             |__/                                                       //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract HBCD is ERC721Creator {
    constructor() ERC721Creator("Hybrid Codes", "HBCD") {}
}