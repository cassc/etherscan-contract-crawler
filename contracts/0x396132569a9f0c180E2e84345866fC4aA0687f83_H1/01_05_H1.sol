// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Haslu Originals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//        )        (   (              //
//     ( /(  (     )\ ))\ )           //
//     )\()) )\   (()/(()/(   (       //
//    ((_)((((_)(  /(_))(_))  )\      //
//     _((_)\ _ )\(_))(_)) _ ((_)     //
//    | || (_)_\(_) __| | | | | |     //
//    | __ |/ _ \ \__ \ |_| |_| |     //
//    |_||_/_/ \_\|___/____\___/      //
//                                    //
//                                    //
////////////////////////////////////////


contract H1 is ERC721Creator {
    constructor() ERC721Creator("Haslu Originals", "H1") {}
}