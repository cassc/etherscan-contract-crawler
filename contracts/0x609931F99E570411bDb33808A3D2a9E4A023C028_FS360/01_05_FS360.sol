// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FullStop Collective
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    ________________________________________________________________        //
//        _____                         __                                    //
//        /    '            /    /    /    )                                  //
//    ---/__---------------/----/-----\-------_/_-----__-------__-----        //
//      /         /   /   /    /       \      /     /   )    /   )            //
//    _/_________(___(___/____/____(____/____(_ ___(___/____/___/_____        //
//                                                         /                  //
//                                                        /                   //
//    _________________________________________________________________       //
//          __                                                                //
//        /    )           /    /                        ,                    //
//    ---/----------__----/----/-----__-----__---_/_----------------__-       //
//      /         /   )  /    /    /___)  /   '  /     /    | /   /___)       //
//    _(____/____(___/__/____/____(___ __(___ __(_ ___/_____|/___(___ _       //
//                                                                            //
//                                                                            //
//                             _                                              //
//    | | _|_  _  ._  o  _    | \     _ _|_  _  ._  o  _.      _              //
//    |_|  |_ (_) |_) | (/_   |_/ \/ _>  |_ (_) |_) | (_| |_| (/_             //
//                |               /             |       |                     //
//                                                                            //
//                                                                            //
//    License: Primary NFT holder is free to display privately and            //
//    publicly in virtual galleries, videos and other non-commercial          //
//    displays produced by the holder of the NFT, as long as the creator      //
//    is credited. This license provides no rights to create commercial       //
//    merchandise, prints for sale, commercial distribution or derivative     //
//    works. Copyright remains solely with the artist/creator,                //
//    FullStop Collective Andrea Pritchard and Olivier Chouinard.             //
//    All Rights Reserved.                                                    //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract FS360 is ERC721Creator {
    constructor() ERC721Creator("FullStop Collective", "FS360") {}
}