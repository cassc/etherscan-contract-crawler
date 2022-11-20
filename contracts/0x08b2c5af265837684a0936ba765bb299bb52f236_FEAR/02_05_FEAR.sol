// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FEARS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//     _ .-') _     ('-.     _  .-')  .-. .-')       .-') _   ('-.    .-')     .-')                                                                                     //
//    ( (  OO) )   ( OO ).-.( \( -O ) \  ( OO )     ( OO ) )_(  OO)  ( OO ).  ( OO ).                                                                                   //
//     \     .'_   / . --. / ,------. ,--. ,--. ,--./ ,--,'(,------.(_)---\_)(_)---\_)                                                                                  //
//     ,`'--..._)  | \-.  \  |   /`. '|  .'   / |   \ |  |\ |  .---'/    _ | /    _ |                                                                                   //
//     |  |  \  '.-'-'  |  | |  /  | ||      /, |    \|  | )|  |    \  :` `. \  :` `.                                                                                   //
//     |  |   ' | \| |_.'  | |  |_.' ||     ' _)|  .     |/(|  '--.  '..`''.) '..`''.)                                                                                  //
//     |  |   / :  |  .-.  | |  .  '.'|  .   \  |  |\    |  |  .--' .-._)   \.-._)   \                                                                                  //
//     |  '--'  /  |  | |  | |  |\  \ |  |\   \ |  | \   |  |  `---.\       /\       /                                                                                  //
//     `-------'   `--' `--' `--' '--'`--' '--' `--'  `--'  `------' `-----'  `-----'  by CABI                                                                          //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                               ARE YOU AFRAID OF DARKNESS?                                                                                                            //
//                                                                                                                                                                      //
//                                    I'M TOTALLY YES!!                                                                                                                 //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//    -LICENCE:                                                                                                                                                         //
//                                                                                                                                                                      //
//      -Extended Editorial ; Can be used to display privately, or in commercial and non-commercial settings, or in groups with an unlimited number of participants.    //
//                            The license includes unlimited use and display in virtual or physical galleries, documentaries, and essays by the NFT holder.             //
//                            Provides no rights to create commercial merchandise, commercial distribution, or derivative works.                                        //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FEAR is ERC721Creator {
    constructor() ERC721Creator("FEARS", "FEAR") {}
}