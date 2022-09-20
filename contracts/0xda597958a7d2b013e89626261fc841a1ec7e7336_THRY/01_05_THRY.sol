// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: by theo thierry
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//           _______    , __   __     _______    ,   _    __  _ __  _ __  _    ,               //
//             /  ' )  / /  ` / ')      /  ' )  /   | )  /  `' )  )' )  )' )  /                //
//          --/    /--/ /--  /  /    --/    /--/,---|/  /--   /--'  /--'  /  /                 //
//         (_/    /  (_(___,(__/    (_/    /  (_ \_/ \_(___, /  \_ /  \_ (__/_  PRESENTS...    //
//                                                                        //                   //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//        |||||||||||||||l|||l|l|||||||||||||||||L||||||||||||||||||||||||| || ||||||||||'     //
//        |||||||||||||||||||||l|||||||||||||||l||||||||||||||||||||||||||L|| |||||` |||||     //
//        ||||||||||||||||||||||||||||||||||||||||||||||||||||| |||||||||||||||||||||||||      //
//        ||||||||||||||||||||||||||||||||| `'|||||||||||||||| |||| L||||| ||'|||||||||| |     //
//        ||||||||||||||||||||||||||||||  '    ||`  |||||||||||  |||||| |||||||||||||+'|||     //
//        |||||||||||||||||||||||||| |'  `        ,,g, `' || ||     ||||||||||||||||||||||     //
//        |||||||||||||||||||||||||||         ,[email protected]@@@[email protected]@@,   ||| , |||||||||||||||||||          //
//        |||||||||||||||||||||| | || +   ,,[email protected]@@@@@|||l%%@@@@@@@@@L| || |||||||||||||  '       //
//        |||||||||| |||||||||| |  |||  ,@@@@@@@MTl`'|[email protected]@@@@@@@@@[email protected]|||  ||  |  |  |           //
//        |||||||||||||||||||||||   |  |[email protected]@@@@@@,,|[email protected]@@[email protected]@@@[email protected]||| || L    |`|            //
//        l]&$|||||||||||||||||        [email protected]@[email protected]@@M|lL&@&@@@@@@@@@@@[email protected]$$r| |            ,          //
//        ||*&@[email protected]@$T%[email protected],,||  |     |@$&@@@$g||||,,[email protected]@@@@@@@[email protected][email protected] |      | |    ,i         //
//        ||||[email protected][email protected]@$$lT%[email protected]@g,,   ,@Mll|||||||%%T&[email protected]@[email protected]@@[email protected][email protected]`       |''   ||`         //
//        ||||||[email protected]@[email protected]@$$$%[email protected]@@@[email protected][email protected]@[email protected]        |    `  |@@K      //
//        || | ||%@[email protected]$&&&[email protected]@[email protected]@@@[email protected]@@ggl|[email protected]@[email protected]$M|            ,@$$F       //
//        ||    ||[email protected]@@@@[email protected]@@@@@@@@@@@@@[email protected]@@[email protected]@[email protected]@[email protected],        ,,[email protected]'        //
//        ||     ||`""TTT|[email protected][email protected]@@[email protected]@@@@@@@@[email protected]$$%@@@@@@@@@@@[email protected]@@@[email protected]@@@@[email protected]         //
//        ||""""J| '| '||[email protected]@@@[email protected]@@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@[email protected][email protected]`         //
//        ||    j|     |[email protected]@[email protected]@@@@@@@@@@@@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]&@@@          //
//        ||    j]      |[email protected]@@@@@@@@[email protected][email protected][email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@@@[email protected]@@@@ML"[email protected]         //
//        ||    -j      [email protected]|[email protected][email protected]@@@@[email protected]@@@@[email protected]@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@[email protected]@L             //
//        ||     j      ]@[email protected]@[email protected]@@@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@@[email protected]@@@@@@@@@@[email protected]@@&L             //
//        ||     j       ` |]@@#@@@@[email protected]&@[email protected]@@@@[email protected][email protected]@@[email protected]@[email protected]@@@&@@@@[email protected]@@@L       `     //
//        ||     j   ,,   ` ]@@l$%@@@[email protected][email protected]@@@@@[email protected][email protected]@@[email protected]@@@@@@@[email protected]@|]@@@L|%@@"       '      //
//        ||  ,.~j=+~+ww+My [email protected]@|"W$%@[email protected][email protected]@@[email protected]@[email protected]@@@@@@@@@@@[email protected]@@W  `                //
//        ||     j ||w+rM j|[email protected]@@|#[email protected]@@@@@@@@@@[email protected][email protected]@@@@@@[email protected]@$$@[email protected]@@@@@]@@@L                  //
//        || ~r" jF  L ,`jLL||''|"[email protected]@@[email protected][email protected][email protected][email protected][email protected]@@@@[email protected]@@[email protected]@@@@$&@@L                  //
//        ||    -jF  L|$|jLL|||||||[email protected][email protected][email protected][email protected][email protected]@[email protected]@@@@[email protected]@@@@@@]@@[email protected]@`                  //
//        ||    jjF  LjL  |L||||||j$$$$$$$$$$$$$$$I#[email protected][email protected]@[email protected]@@@M,@M'"%L    |             //
//        ||    jjk  L"  | I,,,L|||[email protected]@[email protected]$$$&[email protected][email protected]@@@@@*F,.., ,                 //
//        ||    jlF |F~.,|ll]@@@,,,|][email protected]@@@&&@@@&[email protected]@@@[email protected]@[email protected]@@[email protected]@@F"@C @@,  "[                 //
//        |l    |lF||F|   --]@@@|||||@@@@@[email protected]@@@@$#@@@@@[email protected]@[email protected]@@  ]  %@@@@@g `               //
//        |L,    |K |F|  /  ]@@@|g|l&[email protected]@@[email protected][email protected]@@@[email protected]@@[email protected]@@@@@@[email protected]@@     g "*[email protected]@W, `             //
//        || },   F }|  {  ,]@@@2][email protected]$$%@@[email protected]@[email protected]@@@@@[email protected]@[email protected]@@@,    `*<,,#* `               //
//        || }`   L }||'     ,wg$][email protected]@[email protected]@@@[email protected]@@[email protected]@@@[email protected]@@@[email protected],                             //
//        YL=$   LF |     ,M$lLW$Q$$$%@[email protected][email protected]@@@@@[email protected][email protected][email protected][email protected]@@[email protected],           ' |           //
//        ||   ,,LL  ,,wj|$gF'M|[email protected][email protected]%@[email protected][email protected]@@[email protected][email protected]@@@@@@@@[email protected][email protected][email protected]@@w        `            //
//        s&*"`  lM||WMMMWWL|||ll|%[email protected]%@[email protected]@@@@@@@@@@[email protected][email protected],                 //
//        ||,,g$r''l#gW||*< [email protected]|%@@[email protected]@@@[email protected][email protected][email protected][email protected]@g,              //
//        l|&'| `|||l|l&wwLLLl|llTlLl$$$l$Wl%@[email protected]@@@@@[email protected][email protected]@@[email protected][email protected][email protected][email protected][email protected]@,            //
//        |LL|!~L|;||Wwww|||l}'|lLlil|%@[email protected][email protected][email protected][email protected][email protected]@[email protected][email protected][email protected][email protected]$$$$$$$&[email protected][email protected],          //
//        || }}|L||l|$g$F||||||||||||||[email protected]@[email protected]%@[email protected]@[email protected]@[email protected]@[email protected]&@[email protected][email protected]&g        //
//        |`'||L|||;wl$$|||L||||||||||[email protected][email protected][email protected][email protected][email protected][email protected]@[email protected][email protected]$$$$$$$$%$$j$$       //
//        |`|||L||||||jM|l|||||||ww&&lW$&[email protected]@@@@[email protected][email protected]@[email protected]@@$$$$$$$j&[email protected][email protected][email protected]      //
//        ||llL|||||||$l|||||||||||||l&$$$$F$$MW$$$WT%@@[email protected]@[email protected][email protected][email protected][email protected][email protected][email protected]&@Q$Mk      //
//        |||w|||||l|lW||||||||||l|l&%[email protected]$M"llMWlj&@@$&[email protected][email protected]@[email protected]$$jj$$l$$k      //
//        |||||l||||M$|||||||||||||@$$%[email protected]$Wl|[email protected][email protected]|%&M$$$&@$$$$$$$$$$$$&@[email protected]&F      //
//                                                                                             //
//                                                                                             //
//                            _     __  _____    _                                             //
//                             /    / ')  /  '    /                                            //
//                            /    /  /,-/-,     /                                             //
//                           /    (__/(_/       /  artworks, thank you :*                      //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract THRY is ERC721Creator {
    constructor() ERC721Creator("by theo thierry", "THRY") {}
}