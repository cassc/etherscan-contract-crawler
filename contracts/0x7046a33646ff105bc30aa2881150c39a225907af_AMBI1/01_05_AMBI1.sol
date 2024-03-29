// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ambidextrous Nude 1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▄▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀^²≈▄▀▓▓▓▓▓▓▓┘,▄Σ▀▀▓▓▓▌Σ▒▓▓▓▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▀▓▓▓▓▓▓▓.╣▓▓ ╙▄%╙▓▓▓▓▓¬▓▒▒▀∩▓▓▀▓@▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ░░▀▀▀▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▀▓▓∩╒▓▓▓▓▒Σ┐ ▓▐▓▓▓▓ ]#,a╓▓▓▓▄{▄▓▓▓▓▓▓▓▓▓▓▓▓▌░░░░░▀▀▓▓▓▓▓▓    //
//        ░╠φ╬╬░░░░░▀▀▀▀▀▓▓▓▓▓▀▓▀▄▄▄ ▓▓▓▓▓▓µ█⌐▄▓▓▓▓▓▄ ▐▌▀▓▓▓▓▓▄▓▓▓▓▓▀▀░░░░░░░╚╬╬╬╦╦░░░▀▓▓▓    //
//        ░░░░░''       ░░░▀▓▓╬▓▓█▓▓▓▄Æ─▓▓▓▓▌, ▓▓▓▓▓▀Γ ^▐▓▓▓▀▄▓▓▓▀'          ░░░░╠░░╙╬╬╬╬░    //
//        ░       ;╗,,,;░  ░░░╚▓▓▓▓▓▓▌.▀▀▓▀▀╙▓▐└`▓▓▀, ╣▓∩╟▓▓▓▓▓▀'   .           '░░░░░░░░░    //
//        ░Q░ƒƒƒQQ╬╬▓▓▓▓▓▒░╦░░#╫▓▓▓▓▓▓▓W∩─Æµ▓ Γ[ ▐▀┌,∩▓▓▀▓▓▓▓▓▓▒╖µ╦┼▀█╬▒╬╬╖        '░░░╠φ░    //
//        ▓▓▓▓▓▀╩½╦▐╬Ö╠╠Γ╝░   ░╣▀▓▓▓▓▓▓▓▓▓▓▓▓▌▒╙ ]],∩]▀é▓▓▓▓▓▓▀╬╙' ╙╚░╫╬▒╬╝m ░\╖`"ⁿ≥▄╦░░░░    //
//        ╙╠╬▓▓▓▓▓▓▓▓▓▓▀░ ░, ░░╙▓▓▓,▐▓▓▓▓▓▀▓▓▓▐∩⌐j,⌐;;▓▓╬▒╬▓▀▀▒▓▓⌐   ^▀▓▄▓▓▓╖,`''  ╠╬╬▓▓▓▓    //
//        ░▓▓▓▓▓▓▓▓▓▓▀░░░░░░╦▓▌▀▓▓▀ ¥▓▓▓▓Γ╟▓▓▓▐▓  ü┌ ▓▀@▓▓▓▓'▓▓▓▓▌░   ░▓▓▓▓▓▓░╬▓▓⌂  "╙╝╝╦▓    //
//        ╠░▀▓▓▓▓▓▓▄▄░╓░░░░▓▓▓▓▓▓▓▓▒╖▐, ─Θ▐▓▓▓▐▓'` [▄▄▀▀▄▒▀▓ ▓▓▓▓▌░   "▐▓▓▓▓▓▓▀╜ .            //
//        ╣╦╦░╠▓▀░▀▓▓▀▀░╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▌∩╟▓ε ∩ ▓▓▓▓▒▀▓▒ █▀▓▒░     ░▓▀▓▀▀╩░               //
//        ╠░░░░    ╠▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄,▄ ▀▓⌐▓▓▌]▄▐▓▓▓▓▓▓▌`ƒ▒▄▓▓▓M=  ,`╓░▀' ░.-'             //
//        '         ╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▐▒▄ ▓▓▓µ▓╫▓▓▓▓▓▀╔▓▓▓▓▓▓▓▓▓▓φ▀╬▄╬'                   //
//               .░]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▐▓▓▐ ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌░░░░▀╕                   //
//               ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓j▓▌▓▌▐▓▓▓▓▓▓▓▓▌j▓▓▓▓▓▓▓▓▓▓▓▓▓▄╠╬▓▄                  //
//             ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓⌐▓\▓▓ ▓▓▓▓▓▓▓▓▓▄▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄             //
//          .╓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌'▓µ▓ ▒▓▓▓▓▓▓▓▓▓▓▓▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄        //
//        ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓]⌠ '╣▓▓▓▓▓▓▓▓▓▓▓▓▓╨▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓µ      //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄╫ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╟▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌     //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//    ---                                                                                     //
//    asciiart.club                                                                           //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract AMBI1 is ERC1155Creator {
    constructor() ERC1155Creator("Ambidextrous Nude 1", "AMBI1") {}
}