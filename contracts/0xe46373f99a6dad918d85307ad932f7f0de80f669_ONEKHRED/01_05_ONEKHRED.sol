// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1000 Hours Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                             ;;░░φφφφ██████████████████████▓φφφ░░░.                         //
//                         ;░░φφφ████████╣╬╬╬╬╬╬╠╬╠╠╠╬╬╬╬╬╣████████φ▒φ░░                      //
//                      ;░φφφ██████╬╬╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╬╬╣█████▒▒░░.                  //
//                   .░φφ╠█████╬╣╨╨╜╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╨╨╜╬╬╣████▓▒░░                //
//                 ;░φ╬▓███▓╬╠╠╠╬▀  ▒▒'                       ╠╣² ⌐╬╠╠╠╬╣████▒▒░░             //
//               ;░φ╠████╬╬╬╠╬╬╬╬░╬░╬╬╠╠╠╠╠╠╠╠╠ΣΣΣΣΣΣ▒╠╠╠╠╠╠╠╠╬╬▒╬░╬╬╬╬╠╠╠╣╣███▒▒░            //
//             .░φ╬████╬╬╬╬╬╬╬╬╬╬╬╬╬╩╬╩╬╬╬╬╬╬╬░╦╦╦╦╦╦╬╬╬╬╬╬╬╩╬╩▒╬╬╬╬╬╬╬╠╬╠╠╠╬╣███▒▒░          //
//            ;φ╠▓███╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╩▄ ║╬╩````````````````║╬╩ε ╠╬╬╬╬╬╬╬╬╬╬╠╬╠╬╬▓███▒░░        //
//          .░φ╠███▓╬╬╠╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠░╬▒░░░░▒╬╬╬╬╬╬▒░░▒░░╬╠╠╠░╬╬╬╬╬╬╬╬╬╬╬╬╠╬╠╬╣███▒▒░       //
//         .░φ║███╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╝╣╜▒╬╬╬╖╖╖╖╖╖▒╬╬╝╢╜╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╬╬▓███▒░      //
//         ░╠║███╬╬╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬⌐b-░╬╜╙╙╙╙╙╙╙╙╠╬▌[:╞╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╬▓███▒░     //
//        ░╠║███╬╬╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╬╬╬╬▒▒▒▒▒▒▒╬░╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╬╠╬▓███▒░    //
//        φ╠███╬╬╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣,,,,,╓▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╬╬╬▓██▒▒    //
//        ╠███╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓██╬    //
//        ║███▓╝╙└▐▀╙└└└└╙╣╣▀└└└└╙╙╬╝╙└└└└╙╩▌└└║╬╣└└└▓▀└└└└└╙╣└└└╬╬▌└└└└└└└└└╙╫╠╜╙└└╙╚███╬    //
//        ╫███Γ      ╒▓╕      ╔▓   └   @▓      ▐╬╣      ╒▓µ  ▐   ╬╠b      █▓   "  ]▓▌░║███    //
//        ███╬╬▒     ╞▓       ╢▌       ╬⌐      ▐╬╣      ║╬▌  j   ╬╣b      ╬╠       ╚╬╠╬███    //
//        ███╬╣⌐     ╞        ╩        ▀        └`      ╠╬▌  j   ╬╬b      └   4▓,   ╙▓╬▓██    //
//        ███▓▓⌐       █       ╓▌       4      ▐██      ║▓▌  j   █▓▌      █▓   ║╣█   .║▓██    //
//        █████µ      ██      ╓▓▌      á▓      ▐▓▓      ╫▓▌  j   █▓▌      █▓   ╙▀▓▓µ ░▐███    //
//        ▓███▓µ  ╒   ╙   ╓▄   ╙   #   ╙└   ⌐  ▐▓▓   ▄   ╙   ▐µ   ╙   [   █▓   ╔  ╙  !████    //
//        ║███▓██▓██▓▓▓▓▓▓╬╬█▓▓▓▓▓▓╬╬█▓▓▓▓▓▓█▓▓█╬╬▓▓▓╬█▓▓▓▓▓▓╬╬█▓▓▓▓▓██▓▓▓▓╣▓▓▓▓█▓▓▓██████    //
//        ║███▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓▓███╬    //
//        ╠╠███▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓╬╬╬╗╗╗╗╗╗╣╬╬╬▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▓▓███▒    //
//        ⌠╠║███▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▐ ▐╬▓╙╙╙╙╙╙╙╙╙╬╣   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▓▓███╬░    //
//         ░╠╣███▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬█▓█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▓▓███╬░     //
//          ░╠╣███▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╬╬╬╬╬╬▄╓╓╓╓╓╫╬╬╬╬╬╬╣╬╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓▓▓███╬░      //
//           ░╠║███▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬▓,'║╬▓╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╣#, ║╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓▓████╩░       //
//            !╚╠████▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬▓╗╗▓╬╬████████████████▓╬╗#╗▓╬╬╬╬╬╬╬╬╬╬╬╣▓▓▓▓▓██╬╩░        //
//             '╙╠╠████▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▄╓╓╓╓╓╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓▓▓▓███╩░'         //
//               ⌡╚╚║████▓▓▓▓╬╬╬▓,  ╬╬╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╨╣╣▄  ╬╬╬╣▓▓▓▓▓▓███╩╙'           //
//                 "╙╚╠████▓▓▓▓▓▓▓▓@╬╬@@@@@@@@@@@@@@@@@@@@@@@@▓╠▓▓@╬▓▓▓▓▓▓████╩╙'             //
//                   '╙╚╠██████▓▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╣▓▓▓▓▓▓▓████╩╩╙'               //
//                      "╙╚╠███████▓▓▓▓▓▓▓▓╣╣╣╬╬╬╬╬╬╬╬╣╣╣▓▓▓▓▓▓▓▓▓▓█████╩╩╙"'                 //
//                         "╙╚╚╠█████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓██████╬╩╙╙"                     //
//                             "╙╙╚╚╩╬█████████████████████████╩╩╩╙╙"'                        //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract ONEKHRED is ERC1155Creator {
    constructor() ERC1155Creator() {}
}