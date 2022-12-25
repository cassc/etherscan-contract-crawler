// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Danny Kass Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//     _______                                                 __    __                                     ________        __  __    __      __                                   //
//    /       \                                               /  |  /  |                                   /        |      /  |/  |  /  |    /  |                                  //
//    $$$$$$$  |  ______   _______   _______   __    __       $$ | /$$/   ______    _______  _______       $$$$$$$$/   ____$$ |$$/  _$$ |_   $$/   ______   _______    _______     //
//    $$ |  $$ | /      \ /       \ /       \ /  |  /  |      $$ |/$$/   /      \  /       |/       |      $$ |__     /    $$ |/  |/ $$   |  /  | /      \ /       \  /       |    //
//    $$ |  $$ | $$$$$$  |$$$$$$$  |$$$$$$$  |$$ |  $$ |      $$  $$<    $$$$$$  |/$$$$$$$//$$$$$$$/       $$    |   /$$$$$$$ |$$ |$$$$$$/   $$ |/$$$$$$  |$$$$$$$  |/$$$$$$$/     //
//    $$ |  $$ | /    $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |      $$$$$  \   /    $$ |$$      \$$      \       $$$$$/    $$ |  $$ |$$ |  $$ | __ $$ |$$ |  $$ |$$ |  $$ |$$      \     //
//    $$ |__$$ |/$$$$$$$ |$$ |  $$ |$$ |  $$ |$$ \__$$ |      $$ |$$  \ /$$$$$$$ | $$$$$$  |$$$$$$  |      $$ |_____ $$ \__$$ |$$ |  $$ |/  |$$ |$$ \__$$ |$$ |  $$ | $$$$$$  |    //
//    $$    $$/ $$    $$ |$$ |  $$ |$$ |  $$ |$$    $$ |      $$ | $$  |$$    $$ |/     $$//     $$/       $$       |$$    $$ |$$ |  $$  $$/ $$ |$$    $$/ $$ |  $$ |/     $$/     //
//    $$$$$$$/   $$$$$$$/ $$/   $$/ $$/   $$/  $$$$$$$ |      $$/   $$/  $$$$$$$/ $$$$$$$/ $$$$$$$/        $$$$$$$$/  $$$$$$$/ $$/    $$$$/  $$/  $$$$$$/  $$/   $$/ $$$$$$$/      //
//                                            /  \__$$ |                                                                                                                           //
//                                            $$    $$/                                                                                                                            //
//                                             $$$$$$/                                                                                                                             //
//                                                                                                                                                                                 //
//        ,$$llllllllllll[email protected],                                                                                         //
//        $lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllllllllllllllll||@|W|g|@l|lllllllllllllllllllllllllll                                                                                         //
//        [email protected]@@@[email protected]@[email protected][email protected]@@M|llllllllllllllllllllllll                                                                                         //
//        lllllllllllllllllllllllllllllllllllll]@@@@@@@@@@@@@@@[email protected]@llllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllll|||lllllll|g%[email protected]@[email protected]@[email protected]$$$M*%[email protected]                                                                                         //
//        [email protected]@MM%@|l|[email protected]@@@"|||||||||R||||[email protected]@|[email protected]@glllllllllllllllllll                                                                                         //
//        llllllllllllllllllll|@$|||||{%@[email protected]@@@|||,dMlllW||]w$Q|[email protected]$%[email protected]                                                                                         //
//        [email protected]$L||||l"|%@@@@|||$l$$$ll$||M$jl$jM||}||]@Wlllllllllllllllll                                                                                         //
//        [email protected]@||||L||||@@@@|||5mw,,[email protected]@@TMM$F|||j||@@llllllllllllllllll                                                                                         //
//        [email protected]$w||||||||@@@%@gwwgm**||||||||j$k||||g$M|llllllllllllllllll                                                                                         //
//        llllllllllllllllllll]@$g|||||||@@@@$$$||@NM||||*j|[email protected]||g$$|llllllllllllllllllll                                                                                         //
//        lllllllllllllllllllll|%[email protected]%[email protected]@@@@@M|||||F*|lwwWwgI|MN%@|lllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllll||||||jM$2Mj2mMT||||lll|l||||TT%Mw"yllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllj|*|[email protected]$W%RFT%[email protected]%Tj[ll|][email protected]@llllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllj|y|%%[email protected][email protected]|$$l%||[email protected]$L#[email protected]|llllllllllllllllllll                                                                                         //
//        lllllllllllllllllllllllllllll]wl&@l|}4WiLl$Llll|#[email protected]|llllllllllllllllllllll                                                                                         //
//        lllllllllllllllllllllllllllll{[email protected]@g||l|||l||Lll|l|||[email protected]|lllllllllllllllllllllll                                                                                         //
//        [email protected]%@@||||||M"||||w|||||Mlllllllllllllllllllllllll                                                                                         //
//        [email protected]$%[email protected]@g||||||||||||;4|llllllllllllllllllllllllll                                                                                         //
//        [email protected]@@@$$$%@@@@M%%%TT||lllllllllllllllllllllllllllll                                                                                         //
//        [email protected]@@@@@@@[email protected]                                                                                         //
//        [email protected]@@@@@@@@@@$lllllllllllllllllllllllllllllllllllll                                                                                         //
//        llllllllllllllllllllllllllllg%@@@@@@@@@@@@@@|lllllllllllllllllllllllllllllllllll                                                                                         //
//        lllllllllllllllllllllllll|[email protected]@@@@@@@@@@@[email protected]@[email protected]|llllllllllllllllllllllllllllllll                                                                                         //
//        lllllllllllllllllll|@[email protected]%[email protected]@@@@@@@@@@@@@@@@@@[email protected]@gllllllllllllllllllllllllllll                                                                                         //
//        llllllllllllllll|g%[email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@@[email protected]@@@@%@llllllllllllllllllllllllll                                                                                         //
//        lllllllllllllll#[email protected]@@@@@@@@@@@@@@@$M%%@@@@[email protected]@@[email protected]@@@@@@[email protected]                                                                                         //
//        llllllllllllll]@@@@@@@@@@@@@@@$M||||]@@@@[email protected]@$$F||%@[email protected]@$lllllllllllllllllllllllll                                                                                         //
//        [email protected]@@@@@@@@@@@@$N||||||||||||[email protected]$Y||||[email protected]$lllllllllllllllllllllllll                                                                                         //
//        \[email protected]@[email protected]@@@@@@@@@|||||||||||||||||\||||||]@@$WlllllllllllllllllllllllF                                                                                         //
//                                                                                                                                                                                 //
//                                  By Danny Kass / @dannygkass                                                                                                                    //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Danny is ERC1155Creator {
    constructor() ERC1155Creator("Danny Kass Editions", "Danny") {}
}