// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bday Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//          (                  )      //
//       (  )\ )    (       ( /(      //
//     ( )\(()/(    )\      )\())     //
//     )((_)/(_))((((_)(   ((_)\      //
//    ((_)_(_))_  )\ _ )\ __ ((_)     //
//     | _ )|   \ (_)_\(_)\ \ / /     //
//     | _ \| |) | / _ \   \ V /      //
//     |___/|___/ /_/ \_\   |_|       //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract BDED is ERC721Creator {
    constructor() ERC721Creator("Bday Edition", "BDED") {}
}