// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fucking Coral Gifts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                ,,,,,,                                                     ,,,,,,,,                             //
//                           ,@@[email protected]@g,                                        ,[email protected]@[email protected],                         //
//                         ,@$$$$"`     "[email protected],                                ,[email protected]$%MM%$$$$$$$$$$$$$$$g                        //
//                         $$$$$         ][email protected]                          ,@$$$"      $$$$$$$$$$$$$$$k                       //
//                        ]$$$$$        ,[email protected],     ,;@$|||||l$g,,  [email protected]$$$$F     ,@$$$$$$$$$$$$$$$$                       //
//                        #$$$$F        @[email protected]||[email protected][email protected]|||l$$$$$$$     /$$$$$$$$$$$$$$$$$$F                      //
//                        $$$$$L       #$$$$$$$$$$$$$$$$$$#@$$$*`    $$$$$#@l$$$$$$    ;$$$$$$$$$$$$$$$$$$$k                      //
//                        $$$$$L       [email protected][email protected]      [email protected]$$$$$L  ,[email protected]                      //
//                       ]$$$$$k      ][email protected]@$$     ,@[email protected]@[email protected]@$$$$$$$$$$$$$$$$$$$$$$                      //
//                       ]$$$$$$      [email protected]@$$    ,$$$$$$$$$#@@W$$$$$$$$$$$$$$$$$$$$$$$$$$$$$                      //
//                       ]$$$$$$L    ][email protected]@@$$   ,$$$$$$$$$$#@@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$                      //
//                    ,;@j$$$$$$$,  ,[email protected]@@$$g,[email protected]@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$%w,                   //
//               ,;@l|||||[email protected]@[email protected]@[email protected]@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$|||||@w,              //
//            ,$||||||||||$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$%@@[email protected]@@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$F|||||||||L            //
//            ||||||||||||[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@ggl$$$$$$$||||||||g$$            //
//            |||||||||||||[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@l$$$$|||||@$$$$$            //
//            ||||||||||||||[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@MM%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$L|g$$$$$$$$$            //
//            |||||||||||||||%$$$l%@@@@@@@@@@[email protected]@@@@@@@@@@@@NM"|||||||||||*M%@@@@@@@@@@@@@@@MMMMMMMMMMll$$$$$$$$$$$$$$$F           //
//            |||||||||||||||||j%[email protected]@@@@@@@NM"|||||||||||||||||||||||TM%@@@@@@@@@@[email protected]@$$$$$$$$$$$$$$L           //
//            |||||||||||||||||||$$$$$$$$$ll%@@@@M|||||||||||||||||||||||||||||||||||"M%@@@@@@$$$$$$$$$$$$$$$$$$$$$$$$L           //
//            [email protected]|||||||||||||||[email protected]@@|||||||||||||||||||||||||||||||||||||||||%@@[email protected]@@           //
//             lM&[email protected]||||||||||[email protected]@$|||||||||||||||||||||||||||||||||||||g$$$#@@[email protected]@@[email protected]            //
//             l|||||%[email protected]@||||||[email protected]@$|||||||||||||||||||||||||||||||[email protected]$$$$$$$$#@@[email protected]@@[email protected]$l$             //
//             l|||||||||[email protected]||[email protected]@$||||||||||||||||||||||||||g$$$$$$$$$$$$$$#@@[email protected]@@[email protected]@Mll$$$$$             //
//             }|||||||||||||M&[email protected]@$|||||||||||||||||||||g$$$$$$$$$$$$$$$$$$$#@@$$$$$$$$$$$$MMll$$$$$$$$$             //
//             }|||||||||||||||||[email protected]@@||||||||||||||||||||$$$$$$$$$$$$$$$$$$$$$#@@$$$$$$$$$$$$$$$$$$$$$$$$$             //
//             !||||||||||||||||[email protected]@@|||||||||||||||||||[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$             //
//             !||||||||||||||||l$$$$$$$$$[email protected]@@w||||||||||||||||||[email protected]@@[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$             //
//             !||||||||||||||||[email protected]@@[email protected]@||||||||||||||[email protected]@@[email protected]#@@$$$$$$$$$$$$$$$$$$$$$$$$$             //
//             !||||||||||||||||[email protected]@@|||[email protected]|||||||||[email protected]@[email protected]$ll$$#@@[email protected]$$$$$$$$$$$$$             //
//             |||||||||||||||||[email protected]@@|||||||M&$$$$W|||||[email protected]@@[email protected][email protected]@[email protected]$$$$$$$$$$$$[             //
//             |||||||||||||||||[email protected]@@||||||||||||&[email protected][email protected]@[email protected]@[email protected]@[email protected]$$$$$$$$$$$$[             //
//             |||||||||||||||||[email protected]@@||||||||||||||||[email protected][email protected]@[email protected]$$$$$$$$$$$$F             //
//             |||||||||||||||||[email protected]@@|||||||||||||||||||[email protected]@[email protected]$$$$$$$$$$$$L             //
//             |||||||||||||||||[email protected]@@|||||||||||||||||||[email protected]@[email protected]$$$$$$$$$$$$F             //
//             |||||||||||||||||[email protected]@@|||||||||||||||||||[email protected]@[email protected]$$$$$$$$$$$$              //
//             |||||||||||||||||[email protected]@@|||||||||||||||||||[email protected]@[email protected]$$$$$$$$$$$$              //
//             |||||||||||||||||[email protected]@@|||||||||||||||||||[email protected]@[email protected]$$$$$$$$$$$$              //
//             |||||||||||||||||[email protected]@@|||||||||||||||||||[email protected]@[email protected]$$$$$$$$$$$$              //
//             |||||||||||||||||[email protected]@@|||||||||||||||||||[email protected]@[email protected]$$$$$$$$$$$$              //
//              Y|||||||||||||||j$$$$$$$$$$$#@@@|||||||||||||||||||[email protected]@[email protected]$$$$$$$$$$$F              //
//                 "Y|||||||||||$$$$$$$$$$$$#@@M|||||||||||||||||||[email protected]@[email protected][email protected]*                //
//                     '*l||||||[email protected]@M|||||||||||||||||||[email protected]@[email protected][email protected]*`                   //
//                          "Yl|[email protected]@T|||||||||||||||||||[email protected]@[email protected]*"                       //
//                              ]$$$$$$$$$$$#@@L|||||||||||||||||||[email protected]@[email protected]*                           //
//                                "*%$$$$$$$#@@||||||||||||||||||||[email protected]@[email protected]"                               //
//                                     "*%[email protected]@||||||||||||||||||||[email protected]@@*"                                   //
//                                          `"M*l||||||||||||||||||j$$$$$$$$$$$$$$$$$$$M""`                                       //
//                                                '*&||||||||||||||$$$$$$$$$$$$$$$%*'                                             //
//                                                     "*l|||||||||$$$$$$$$$$$M"                                                  //
//                                                         `"Yl||||$$$$$$%*`                                                      //
//                                                              '*Y#N*"                                                           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FCG is ERC721Creator {
    constructor() ERC721Creator("Fucking Coral Gifts", "FCG") {}
}