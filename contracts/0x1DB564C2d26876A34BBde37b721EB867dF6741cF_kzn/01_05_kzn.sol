// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kaizen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//     __               _                             //
//    [  |  _          (_)                            //
//     | | / ]  ,--.   __   ____  .---.  _ .--.       //
//     | '' <  `'_\ : [  | [_   ]/ /__\\[ `.-. |      //
//     | |`\ \ // | |, | |  .' /_| \__., | | | |      //
//    [__|  \_]\'-;__/[___][_____]'.__.'[___||__]     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract kzn is ERC721Creator {
    constructor() ERC721Creator("kaizen", "kzn") {}
}