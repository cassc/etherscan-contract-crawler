// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Friends From the Places Between Times
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    This contract binds together significant memories, experiences, and lessons from my past.      //
//    All of these elements have morphed and amalgamated into mutant fragments of my psyche.         //
//    The older I get the more I realize I understand the world around me better if I have my        //
//    imaginary friends there with me to help me understand. The motifs and symbols present in       //
//    them are how I analyze my memories in the way that feels most comfortable to me. It's          //
//    formed a complex relationship between my past and I because I recognize now a lot more of      //
//    the pain I've felt and ignored or didn't understand growing up. Clarity is strange. These      //
//    powerful reflections of my past are conjured and moderated by weezards. Weezards vary in       //
//    size and strength depending upon the strength of the memories. Weezards themselves are         //
//    chronicled by the clerk type Time Weezards. They just catalog the existence of Weezards        //
//    and the periods of time they are attached to. This time weezard is bound to the blockchain     //
//    and keeps track of "Reddy's Friends From the Places Between Times."                            //
//                                                                                                   //
//                                                                                                   //
//                                                ⌐ƒ                                                 //
//                                              ▄`▐                                                  //
//                                             █  '█                                                 //
//                                            ▐`    ▀╕                                               //
//                                            █▄` √▌  █                                              //
//                                          ,Å   ƒ╔   ▐                                              //
//                                         ▄▀   █ ▀═Φ ██   ,                                         //
//                                        ]█    "▐▀,`   ╚. ▐\                                        //
//                                     ,  ▐█ƒ    ▌ █     █  ▌▐                                       //
//                                   ╓"▐   ██ⁿ` █▄ `▐    █  ▐ ▀                                      //
//                                  ▐▀ ▐▄ Æ"     █  █   ╧▀▄ ▐  ╚                                     //
//                                  █    '    ,,¿  ▄▄∞8   '    ,                                     //
//                          ,⌐,,     " █"     "+    ╔      "█▄'      ,,╓                             //
//                          ▀█  ""`▀P▓█       ,▌╓, ,⌐█       ╚██▀▀▀╙   █                             //
//                            ▀▄,  .,            ▐▄             .  ,╓═                               //
//                               "═∞╦╖,`'"ⁿ*^ⁿ*══*═══ªⁿ²²""`  ,▄▄╩"`                                 //
//                                .▄▀╚███▀██&▄▄▄╖╓⌐▄▄▄▄▄████▀▀▀███                                   //
//                                ██    █ █Γ█▓ █`██"█'▌▐▌▀,▀    `█▌                                  //
//                                 "▌   ╚█▄▄▄▄+▄Ç▄█∞▐Σ═█▄███    ▄                                    //
//                                 ¿▌    ▀▌▌ ▀█▀▀▀██▀▀▀▌ `█     █                                    //
//                                ,█      '█▄  ,▐    ╝ ▐▄"      ▐█                                   //
//                                  ╙ⁿ∞      "≈▄█  `█∞"      ,P╜"                                    //
//                                    ▄█,      `██▄⌐╛      ,,█,                                      //
//                              ,╥Ä▀▀''▀╜"    ┌╔,██▄ⁿ,    "`    ▀═▄,                                 //
//                          ,▄P`  ⌐m"        P█▄█████▄*,       "ⁿ∞  ▀█╖                              //
//                        ╓╨    ▄▀        ╔╜`@██▀▀▀████,"╖         ▀▓, ▀█,                           //
//                     ,█▀   ─█▀      ,╓*',▄█'    █▌  ╚7▀╦ ⁿ~         █L  █▄                         //
//                    ▄▀    ▄█     ╓∞"  ╔█`     ╒██ ,     `ⁿ, '3╕      ╙█,  █╖                       //
//                  ╓█`   ╔█'       ,╔█▀       .████▀         "w,        █,  ▀▌                      //
//                 ▄█    j█    ,╓▄▀▀             ▄██             '^∞,    ╘█▌  "█                     //
//                j█`    █⌐  ▐█                 ████▄B               ,█   ██   '█                    //
//               ╔█▌    ██   ███████▄═         `` ▐██          ⌂██████▌▌  ]█⌐   ▀▌                   //
//               █▌     ██   ╔▀ `              ╖  ██,╓▄███▀         ``▌▌   █`    █▄,                 //
//              ▐█      ▀█   ▐)                 "█████▀"'            ▐▐    █∞∞═╚``'█                 //
//              █`      r█    ▌,                 █ ▀██,              █▌   ╒█Γ   ,⌐▄█                 //
//            █▌"`"╨7ⁿ∞W0█▄    ▄,                    ╙███╖          ╛▀    ██▀"``  ,█                 //
//           █╨           ▀▄    \\                      ╙███▄     ╓▀F    ▐▀██▓ █,╓█▀                 //
//          ██ⁿ            █▌    ╘▄-              ,        ╙╙▀  ,'A`    ▄═                           //
//          ╚█▌µ,        ,▄▓██▄    "-`.          ▄█          ,═."`   .╔"                             //
//           █████████▄ª╙████"'╙∞,    `═╗;⌐,    ┌███    ,⌐═S▄^     ╔╜`                               //
//             ╙▀██W,,█  '▌╝╛    █        `"▀▄▄▄▄██████▄*'         █                                 //
//                             ╓▀ - .            `                 ,█                                //
//                             ╩▀╜╩"""▐&                     ▄`╙"ⁿ**"`                               //
//                                    2▓▌╔██████/   .█▀██▓▄Çy█                                       //
//                                      ▐█X─ ⌐/▌█▌▄█▀   Y//▓Ü                                        //
//                                       ▀▌     ╜▀`       ,█                                         //
//                                         ]╔            ╔█`                                         //
//                                           ╙4          █                                           //
//                                             ╚▓     ,▄'                                            //
//                                              ▀,  ,Æ'                                              //
//                                               █▄²                                                 //
//                                                                                                   //
//                                                                                                   //
//    ---                                                                                            //
//    asciiart.club as always ty <3                                                                  //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract FFPBT is ERC721Creator {
    constructor() ERC721Creator("Friends From the Places Between Times", "FFPBT") {}
}