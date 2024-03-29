// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cosmos Astro Art
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                   //
//                                                                                                                                                   //
//                                                                                                                                                   //
//       ______                                   ___         __                ___         __                                                       //
//      / ____/___  _________ ___  ____  _____   /   |  _____/ /__________     /   |  _____/ /_                                                      //
//     / /   / __ \/ ___/ __ `__ \/ __ \/ ___/  / /| | / ___/ __/ ___/ __ \   / /| | / ___/ __/                                                      //
//    / /___/ /_/ (__  ) / / / / / /_/ (__  )  / ___ |(__  ) /_/ /  / /_/ /  / ___ |/ /  / /_                                                        //
//    \____/\____/____/_/ /_/ /_/\____/____/  /_/  |_/____/\__/_/   \____/  /_/  |_/_/   \__/                                                        //
//                                                                                                                                                   //
//                                                                                                                                                   //
//                                          ,,╓╦g▄▄▄▄▄▄╓,                                                                                            //
//                                     ╓g▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄                                                                                       //
//                                  ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▄,                                                                                   //
//                               ╓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▄                                                                                 //
//                             ,▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▄                                                                               //
//                            ▄▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓╢╫▓▓▓▓██▓▌                                                                              //
//                           ▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╨▒╜▒▒▒▒╢▒▒▒▒▒▓▓▓▓█▓█                                                                             //
//                          ▓████▓▓▓▓▓▓▓▓▓▓▓▓▓╣▓▓╫╣╣▒▒▒▒▒╬╣▓▓▒@▓▓▓▓▓▓▓▓██                                                                            //
//                         ▐███▓▓▓▓▓▓▓▓▓▓▓▓▓▓╢▓▓▓▓╣▓▒▒▒▒╢▒▓▓▒▒▒▒▓▓╣▒╣╫▓██▌                                                                           //
//                         ███▓▓▓▓▓▓╣╢╫▓▓▓▓▓▓▓▓▓▓▓▓▓╣▒▒▓╣▒▒▒▒▓Ñ▒▒▒▒▒╢▒▒▓██                                                                           //
//                         ██▓▓▓▓▓▓▓▓╢▓▓▓▓▓▓▓▓▓▓▓╣▓▓▓▓╣╢▓▓╢▒╬╢▒▒▒▒▒▒▒▒▒╢██µ                                                                          //
//                         ███▓╣╣▓▓▓▓▓▒╫▓▓▓▓▓▓▓▓╢╣╣▒▓▓▒╫╢╫╣▓╢╢╣╣▒╬▓▒▒╢▒╣▓█▌                                                                          //
//                         ██▓▓╣▓╢▓▓▓▓▒▒▒▒║╢╣▓▓╣╢╬▒▒▒▒╙╢▒╢╣▓▓▓▓╢▓▓▓▒▒▒▒╢▒▓                                                                           //
//                         ▓█▓▓▓╫▓▓╣╣▒▒▒▒▒░▒╣╣╣▒╫╣╣▒▒░]╢╣╢▓▓▓▓▓▒▒▓╢▒╢▒▒▒╢▓                                                                           //
//                          █▓███▓▓▒▒▒▒▒▒░░╓╢▒▒▒░░▒▒╓▒╢╫╫╣▓▓▓▓▓╣▒▒▓╣╢╣▒╫▓                                                                            //
//                          ▐██▓▓▓█▓▓╣╫@▒▒▒▒▒▒▒▒▒▒▒╬╫╬▒▒▒▒▒▒╢▒▓▒▒╣▓▓▓╢▒╫▀                                                                            //
//                           ╙█▓▓▓▓▓█▓▓▓▓▒╢▒╢╣▒▒▒▒▒╝╣╫@▒▒▒▒▒▒▒▒╣╣╢╫╣╣╫╣╝                                                                             //
//                             ▀█▓▓▓█▓▓▓▓▓▒▒╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▒╫▓╣╣╣▓                                                                               //
//                              ╙████▓▓▓▓▓▓▓╣╢╣╬@╬╢▒╢▒▒▒▒▒▒▒▒▒▒▓▓▓╫▓`                                                                                //
//                                 ▀████▓▓▓▓▓▓╣▓▓╣╣╫▒▒▒▒▒▒▒g▓▓▓▓▓╝`                                                                                  //
//                                   `▀█▓▓▓▓▓▓╢▒╢▒▒╢╫╢╣╫▓▓▓▓▓▓▀`                                                                                     //
//                                        ▀▀▀▓▓▓╣╣▒╢╣@╬▓╩▀▀                                                                                          //
//                                                                                                                                                   //
//                                                                                                                                                   //
//       ______                                   ___         __                ___         __                                                       //
//      / ____/___  _________ ___  ____  _____   /   |  _____/ /__________     /   |  _____/ /_                                                      //
//     / /   / __ \/ ___/ __ `__ \/ __ \/ ___/  / /| | / ___/ __/ ___/ __ \   / /| | / ___/ __/                                                      //
//    / /___/ /_/ (__  ) / / / / / /_/ (__  )  / ___ |(__  ) /_/ /  / /_/ /  / ___ |/ /  / /_                                                        //
//    \____/\____/____/_/ /_/ /_/\____/____/  /_/  |_/____/\__/_/   \____/  /_/  |_/_/   \__/                                                        //
//                                                                                                                                                   //
//                                                                                                                                                   //
//                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOONSHOT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}