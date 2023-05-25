// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blockchain Demystified NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    :::::::::::::::::::     //
//    :::::::.::.::.:.:::     //
//    :.: :.' ' ' ' ' : :     //
//    :.:'' ,,xiW,"4x, ''     //
//    :  ,dWWWXXXXi,4WX,      //
//    ' dWWWXXX7"     `X,     //
//     lWWWXX7   __   _ X     //
//    :WWWXX7 ,xXX7' "^^X     //
//    lWWWX7, _.+,, _.+.,     //
//    :WWW7,. `^"-" ,^-'      //
//     WW",X:        X,       //
//     "7^^Xl.    _(_x7'      //
//     l ( :X:       __ _     //
//     `. " XX  ,xxWWWWX7     //
//      )X- "" 4X" .___.      //
//    ,W X     :Xi  _,,_      //
//    WW X      4XiyXWWXd     //
//    "" ,,      4XWWWWXX     //
//    , R7X,       "^447^     //
//    R, "4RXk,      _, ,     //
//    TWk  "4RXXi,   X',x     //
//    lTWk,  "4RRR7' 4 XH     //
//    :lWWWk,  ^"     `4      //
//    ::TTXWWi,_  Xll :..     //
//    =-=-=-=-=-=-=-=-=-=     //
//                            //
//                            //
////////////////////////////////


contract BD is ERC721Creator {
    constructor() ERC721Creator("Blockchain Demystified NFT", "BD") {}
}