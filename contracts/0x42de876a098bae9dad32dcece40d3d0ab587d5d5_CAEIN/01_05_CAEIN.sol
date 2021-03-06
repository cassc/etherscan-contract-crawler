// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Caelestis Insania
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                             ,                                      //
//                                                                                           ,▄▌                  ,╓╓╖╖╓,,,           //
//                                                                                         ╓███[              ,;¿╖╖▒╢▒▒▒▒▒▒▒▒▒╢@╓     //
//                                                                                      ╓@░██╣▌░          ,╔▒p▒▒▒▒▒▒▒▒▒▒░░░░▒░░░ ▒    //
//                                                                                     ░████░█░░ç     ,,╓╓▒▒▒▒▒▒░░''░░░░▄▄▄█▀░░░╜     //
//                                                                                   g░████░░▌░░,╖  ,/m▒▒▒▒▒▒▒░░░▄▄▄█████▀░░░ ╙       //
//                                                                                 ╓░▒████░░░└░▒▒▒▒╢▒▒▒▒▒▒▒▄▄░████████░▀░'░░          //
//                                                                               ╓░▒▒█████░█░░░░░░░░░▒▄░░████░░░░░░█░╜░░░             //
//                                                                            ╓░░╝╜`▐███████░░░░░▄█▀░███▀░░░░███░░░╜▒`                //
//                                                                        ,g░░╣╜▄▄▄▄███████░░,▄@░▄███░▒╢░░██████░▒╝"                  //
//                                                                    ,g▄░░╙╜╙`███▀░╠███████████▀.▄M▒║╫░░█████░░"                     //
//                                                              ,,╓n%╠░╜▒╜' ,6╝╙▄░░░░░████████.⌐∞@"j░░███████╜                        //
//                                                ,,╓[email protected]@M╙`,╥@╜`    ░▒▒░  ,ⁿ    ▐████░█████░⌐⌐∞É,,▄░███████╜                          //
//                                         ,╥▄░░░╜╜,╓╖╖@╩╜"        ╟╣▒▒▒░      ,████░░███▀▄▄m╝¬⌐═]░░░█████┘                           //
//                                   ,╓▄░░░░╢╣▒░░░░▀"             ╓▒▒╜`        ████░░░█▀", ▐▌"`  ░░░░████░▌                           //
//                               ,▄░░░░░░░░██▀"`                  ║▒  .        █████░██ H▀`╜ƒ   ]╢╣╢░░░███░░@,                        //
//                           ,æ░▒▒▒░░███▀"                       ╓▒░`░`       ▐███░░Ñ█~  ╜      ]╣▒▒╢░░░███████╖                      //
//                        ,@░▒▒g███▀▀                           ╓▒ ¿"       ╓╓██░░▒╝░           ░▒▒▒▒╢░╙╙▒╠░░░███                     //
//                      ╔░▒▒▄███▀                             ,╫▒╜        ▄░▒██░░░░u             ╙▒▒▒░░  `░▒╢╫░░░░µ                   //
//                   ,Θ░▒▄██▀`                             ╓╥▒▒`      ,╥░░██░█░░░░▌"               ╙╜╜▒ ╓''╙▒└╫░░█▌░                  //
//                 ,▒¿░░░▀`                        ,,╖─▒▒░ ` "    ,╓[email protected]░██░░█░░░░██Γ                   ╙╜   '` ╟░░█▌░ ╓░               //
//                '¿▒░░╜                   W╖╖╖╖~┌ ,             ╢░░████████░███▀▒                         ╘ ░╢░██░ ░ ╓░              //
//               ,▒╜╜                                          ╫░████████░████ ▄░╜                          ,░░██░░  ░ ╓░             //
//              ,▒`                                            ███████░██░██`  ▌                           ,▒█░███╜  ░ ╓░             //
//             '                                           ██████▀▀▀`"`█▀`  ,`                            ,▒█░█░█▀   ░ ╓░             //
//                                                      ╢░╢░░▀░╜`     █▒`                                 ▄░░░░█▀  '▒ ╓░▌             //
//                                                     ,░▀▀─▄▄Ñ    .^`                                  ▄░░░░░█`  '▒░╓█▌              //
//                                                   ╓█" ` █╜`╜                                       ╓░░░░██▀   ,░ ▄█▀`              //
//                                                  █`    ▐`                                         #▒╢▄█░▀   ,░░g██▒`               //
//                                                ,▀ `    █                                          ,░█▀`   ,▒,g░█▀╜                 //
//                                                ▌       ▌                                        d▀`     ╓╜╓@░█▀╜                   //
//                                               ]▌       ║                                        -   .r▒░▄█░█▀                      //
//                                               ▐L       L                                       .+ ',╓@░█░▀`                        //
//                                                L                                           -'  ,╖@░░░░╜                            //
//                                                                                         ,╓▄@░░▀▀╜╙                                 //
//                                                                                    ─*╜╜╙"`'                                        //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CAEIN is ERC721Creator {
    constructor() ERC721Creator("Caelestis Insania", "CAEIN") {}
}