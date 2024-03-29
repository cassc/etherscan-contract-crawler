// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Good Morning Monthly
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//                                 ▄                                     //
//                              ▐▀   ▀█▄                                 //
//                              █  ▓█▀ ▀█                      █████▄    //
//                               █ █ ▄▄ ▐█                    █ █ █ █    //
//                               █▄▀███  ▐█                  █▀█▀██▄█    //
//                                █▄      █▄                 █▐    ██    //
//                                 █       █                █▀      █    //
//                                  █       █               █      ▓▌    //
//                                   █       █              ▌      █     //
//                                   ▐█       █            █      ▐█     //
//                                    █▌  ▄▀▄ ▐▌          █       █▌     //
//                                     █       █         █▌  ▄    █      //
//                                     ▐█      ▐█        █       ▄█      //
//                              ▄██▀▀▀█▄▀█      ▀▌     ▄█        █       //
//                             █▀      ██▀█      ▐█  ▄█         █        //
//                             █        ▀██        ▀▀    ▄     █▌        //
//                             █▄      ▐████▄▄             ▀▀▄ █         //
//                              █▌     ██     ▄█▀▀▀▀▀█▀██▄    ▐█         //
//                          ██████▄     █▄ ▀         ▄▐  ▀█   █▌         //
//                         █▌    ██      ▀█▄            ▐  ██ █          //
//                        █▌      ▀█▄  ▄▓▓ ▀███▄▄▄          ▐██▌         //
//                         █        █▌ █  ▀▄▐█  █  █▄▄        ▀██        //
//                          ██   ▀▀  ▀██   ███▄▀ ▄ ▓▓█           ██      //
//                          ▐██▌       ████████ █  ▌ █▄           ██     //
//                           █ ▀█▄  █ █▌█   ██ █  ▐   █▄          ▐█     //
//                           █▌  ██ █  ▀█▌▓▀█ ▐▌  ▐     █▄        ▐█     //
//                           ▐█    ▀█████▀  █ █    ▌     ▀█▄      █▌     //
//                            █            ▐  █             ▀     █      //
//                           ▐█            █  █                  ▐█      //
//                            █            ▀  █                  █▌      //
//                            ██               █                 █       //
//                             ██              ▐█  ▐▄           ▐█       //
//                              ▀█               █   ▀▄         ██       //
//                                █▌              ▀█▄          ██        //
//                                 ▀██                      ▄██▀         //
//                                    ██████████████████████▀            //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract GMM is ERC721Creator {
    constructor() ERC721Creator("Good Morning Monthly", "GMM") {}
}