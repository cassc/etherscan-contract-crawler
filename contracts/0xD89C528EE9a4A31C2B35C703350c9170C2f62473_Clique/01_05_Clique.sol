// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Clique no saiba mais
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//       ▄██████_            ██▌  ▐█▌                                                   _██▌             //
//     _██▀`   ¬_  _    _     __  ▐█▌ _ ___      _                ___   _  _   __ ___             _ _    //
//     _▀██▄,      ██▀▀███_  ██▌  ▐█▌██▀███_  ██▀▀███        ▐███▀███▄█████▄_  ██▀▀██▄  _██▌ _▄██▀▀█_    //
//       -▀▀███▄_    ,▄▄██▌  ██▌  ▐██    ▐██_  _,▄▄██▌       ▐██___▐██¬_ `██_   _,▄▄██▌  ██▌ ▐██▄_       //
//    _      ¬██▌_╓██▀▀▀██▌  ██▌  ▐█▌   _▐██_▄██▀▀▀██▌       ▐█▌   ▐██    ██_ ▄██▀▀▀██▌  ██▌  -▀▀███     //
//      █▄▄▄▄▄██▀_▐██ç;▄██▌  ██▌  ▐██▄▄╓▄██▀_██▄;;▄██▌       ▐█▌   ▐██    ██__██▄;;▄██▌  ██▌ ╒▄;,,██▌    //
//      ▀▀▀▀▀▀▀__ _▀▀▀▀└╙▀▀ _▀▀"  ╙▀▀└▀▀▀▀    ▀▀▀▀`▀▀"       "▀▀_   ▀▀_   ▀▀   ▀▀▀▀¬▀▀¬  ▀▀' "▀▀▀▀▀-     //
//                                                                                                       //
//    “Clique no saiba mais” [“Click on learn more"] is a work from the “Detremura” series that          //
//    presents audios from about 600 ads extracted from the Meta Ad Library - a transparency tool        //
//    that lists active and inactive campaigns displayed on the social networks Instagram and            //
//    Facebook, as well as on the Messenger app. The selection of ads adds up to a total of 8            //
//    hours of duration to be played on a parametric speaker along with a vinyl cutout.                  //
//    Pedro Victor Brandão, 2023.                                                                        //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Clique is ERC721Creator {
    constructor() ERC721Creator("Clique no saiba mais", "Clique") {}
}