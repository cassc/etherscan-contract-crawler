// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Addiction
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                      //
//                                                                                                                                                      //
//      ______   __  __        __                  __                              __                                                                   //
//     /      \ /  |/  |      /  |                /  |                            /  |                                                                  //
//    /$$$$$$  |$$ |$$ |      $$/   _______       $$ |        ______    _______  _$$ |_                                                                 //
//    $$ |__$$ |$$ |$$ |      /  | /       |      $$ |       /      \  /       |/ $$   |                                                                //
//    $$    $$ |$$ |$$ |      $$ |/$$$$$$$/       $$ |      /$$$$$$  |/$$$$$$$/ $$$$$$/                                                                 //
//    $$$$$$$$ |$$ |$$ |      $$ |$$      \       $$ |      $$ |  $$ |$$      \   $$ | __                                                               //
//    $$ |  $$ |$$ |$$ |      $$ | $$$$$$  |      $$ |_____ $$ \__$$ | $$$$$$  |  $$ |/  |__                                                            //
//    $$ |  $$ |$$ |$$ |      $$ |/     $$/       $$       |$$    $$/ /     $$/   $$  $$//  |                                                           //
//    $$/   $$/ $$/ $$/       $$/ $$$$$$$/        $$$$$$$$/  $$$$$$/  $$$$$$$/     $$$$/ $$/                                                            //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//      ______                                       __      __                                                 __                                      //
//     /      \                                     /  \    /  |                                               /  |                                     //
//    /$$$$$$  |  ______   __     __  ______        $$  \  /$$/______   __    __   ______    _______   ______  $$ | __     __  ______    _______        //
//    $$ \__$$/  /      \ /  \   /  |/      \        $$  \/$$//      \ /  |  /  | /      \  /       | /      \ $$ |/  \   /  |/      \  /       |       //
//    $$      \  $$$$$$  |$$  \ /$$//$$$$$$  |        $$  $$//$$$$$$  |$$ |  $$ |/$$$$$$  |/$$$$$$$/ /$$$$$$  |$$ |$$  \ /$$//$$$$$$  |/$$$$$$$/        //
//     $$$$$$  | /    $$ | $$  /$$/ $$    $$ |         $$$$/ $$ |  $$ |$$ |  $$ |$$ |  $$/ $$      \ $$    $$ |$$ | $$  /$$/ $$    $$ |$$      \        //
//    /  \__$$ |/$$$$$$$ |  $$ $$/  $$$$$$$$/           $$ | $$ \__$$ |$$ \__$$ |$$ |       $$$$$$  |$$$$$$$$/ $$ |  $$ $$/  $$$$$$$$/  $$$$$$  |__     //
//    $$    $$/ $$    $$ |   $$$/   $$       |          $$ | $$    $$/ $$    $$/ $$ |      /     $$/ $$       |$$ |   $$$/   $$       |/     $$//  |    //
//     $$$$$$/   $$$$$$$/     $/     $$$$$$$/           $$/   $$$$$$/   $$$$$$/  $$/       $$$$$$$/   $$$$$$$/ $$/     $/     $$$$$$$/ $$$$$$$/ $$/     //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Addict is ERC721Creator {
    constructor() ERC721Creator("Addiction", "Addict") {}
}