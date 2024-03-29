// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phettaverse
/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                           ,▄═ⁿ*¬                                 //
//                                          ª     ▌ ▄                               //
//                                   ,▄,            ▐                 ▄═══⌐▄        //
//                                /`     ⁿ▄  \▄∞═ⁿMM▀¬,              ▌       ⁿ▄     //
//                               ▐   ▌  N  \▀          `≈            \         L    //
//                                t   ╦   τ ╘             ▄        ,¬ⁿ▀        ▐    //
//                                  ═,  T══                ▄   ▄═"      `╔w,,,∞     //
//                                    ▐"^             ╒██  ▐F          ▄▀           //
//                                    ▐          ███   ▀▀           ¿▀              //
//                                     ╕          ▀▀        ▌    ,*                 //
//                                      \                   ▌ ,╨`                   //
//                                      ▄▀═▄                █▀                      //
//                                   ▄ⁿ       ``"*═▄    ,▄▄▄                        //
//                              ,▄^`                 '═▄████                        //
//                   ,^`ⁿ ,▄═ⁿ`                        ▌▀██▀                        //
//                  ,                       ,          ╟                            //
//                  ▐    ▐     ,,▄.àA∞╧▀"▀`            ▐                            //
//                   ▀w ,╝`                                                         //
//                                                    ▄═▀""═,                       //
//                                        ▌       ▄═`        ▀▄                     //
//                                        ▌     `              )  ▄∞═∞              //
//                                        ▌                     ▀      ▌            //
//                                        ▐        ,▄▄▄,       ▌                    //
//                                          "^*^"`       ≈           ,▀             //
//                                            ▐     ,▀    '▄       ,²               //
//                                           Æ     ▄         "^^^"                  //
//                                         ▄      r                                 //
//                                       ,▀      ▀                                  //
//                                       ▌     ▀▀                                   //
//                                              █                                   //
//                                       \      Å                                   //
//                                        ▀u, ,P                                    //
//              ____  _   _  ____  ____  ____   __  _  _  ____  ____  ___  ____     //
//             (  _ \( )_( )( ___)(_  _)(_  _) /__\( \/ )( ___)(  _ \/ __)( ___)    //
//              )___/ ) _ (  )__)   )(    )(  /(__)\\  /  )__)  )   /\__ \ )__)     //
//             (__)  (_) (_)(____) (__)  (__)(__)(__)\/  (____)(_)\_)(___/(____)    //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract Phetta is ERC721Creator {
    constructor() ERC721Creator("Phettaverse", "Phetta") {}
}