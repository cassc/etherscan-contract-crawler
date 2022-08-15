// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KREEPSHOW
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//         ) (           (    (       )    )              //
//      ( /( )\ )        )\ ) )\ ) ( /( ( /( (  (         //
//      )\()|()/((   (  (()/((()/( )\()))\()))\))(        //
//    |((_)\ /(_))\  )\  /(_))/(_)|(_)\((_)\((_)()\ )     //
//    |_ ((_|_))((_)((_)(_)) (_))  _((_) ((_)(())\_)()    //
//    | |/ /| _ \ __| __| _ \/ __|| || |/ _ \ \((_)/ /    //
//    | ' < |   / _|| _||  _/\__ \| __ | (_) \ \/\/ /     //
//    |_|\_\|_|_\___|___|_|  |___/|_||_|\___/ \_/\_/      //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract KREEP is ERC721Creator {
    constructor() ERC721Creator("KREEPSHOW", "KREEP") {}
}