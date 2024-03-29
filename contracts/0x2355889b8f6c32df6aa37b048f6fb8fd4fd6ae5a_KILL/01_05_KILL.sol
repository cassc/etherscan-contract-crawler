// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KIMO'S KONUNDRUM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ▒▒█▓██▓#▓▓▓▒▓╬███▓▒▓▒▒▒▒▒▒▒▒▒▀▀▀████████████████████████████████████████▒███████    //
//        ██▀▀▀▀╙▀╙╩╩▀º╙▀▀▀╙▒▓▓╫▒▒▒▒▒▒▒▒▓█████████████████████████████████████████▀███████    //
//        ██ ▐▄╫ ¥▄∩▌R,B▄¥╔╣▒▒▒▒▒▓▓▒▒▒▒▀▀▀▀███████████████████████████████████████▒███████    //
//        ██,▄,▄▄▄▄▄▄▄▄▄»▄▄▐█████████▓▓▓▒▒▒▒▒▒▒▒▓▓▒▒▀▀▀███████████████████████████▒███████    //
//        ██▒████▄▓█▓███▌████████████▌▓▓▓▀▀▌└└└╚╙▓▓▓▒▒▒▒▒▓▒▒▒▒▒▒▒▀▓██▀▓███████████▌███████    //
//        ████████▌██████████████████▓████▓▒▒▓▄    ╙▀▀████████▓▓▓▒▒▒███▓▒█████████████████    //
//        ████████▌███████████████████████  ╙╫▒▒æ⌐   .└▀██████▀▒▒█████████████████▓███████    //
//        ████████▌███████████████████████    └╝▒▓╙w   √,▀██▌.╙▓██████████████████▌███████    //
//        ████████▌███████████████████████Q¿]   ▐    ½    └Y  .███████████████████▌███████    //
//        ████████▌██████████▓██████████████████▓▌    `      .████████████████████▌███████    //
//        ████████▌████████████████████████████████      ,╓▄▄█████████████████████████████    //
//        ████████▌█████████████████████████████████▓#▀▒▒▒▒▒▀█████████████████████▌███████    //
//        ██████████████████████████████████████████▒▒▒▒▒▒▒▒▒▒█████████▌▀█████████████████    //
//        ████████▓█████████████████████████████████▒▒▒▒▒▒▒▒▒▒▒████████h  ▀███████████████    //
//        █████████▓████████████████████████████████▌▒▓▒▒▒▒▒▓▒█████████▒╒  ~████████▓█████    //
//        █████████████████████████████████████████████▒▒▒▒▒▒▓█████████▌└ æ▐██████████████    //
//        ██████████▓██████████████████████████████████████████████████▒  ▌███████████████    //
//        ██████████╣█▀█▀█████████████████▀▀███████████████████████████▓ ∩████████████████    //
//        ██████████▌▀▓█▄██████████████▀▒▒▓█████████████████████████████ M████████████████    //
//        █████████████████████████████▒▒█████████████████████▀▀██▒▒║▀██.█████████████████    //
//        █████████████████████████████▒▒████████████████████▌▒▒▒▒╫▒▒▒▒███████████████████    //
//        ██████▀▀███▀▀▀███████████████▒▒████████████████████▒▒▒▓▒▒▒╜╩▓▒▒▒████████████████    //
//        █████▒▒▒▒▀▒▒▒▒╫▀███▌└██∩███████████████████████████▓▒▒▓╙[▀╗▓▒▒▒▒║███████████████    //
//        ████▒▒╫▒▒╫▒▒▓▒▌█▌ ▀▌░G█ ██████▒▀██████████████████▒█▌ ▓▒▒▒▒▒▒▒▒▒▒███████████████    //
//        ███▓▌▄╫▌╙▓▒▒╙║▌ ▀│░▓▄▓│m╫██▒▒▒▒▒║██████▒▒╢▒▒║▀████▌╠█▓▓▒▒▒▒▒▒▒▒▒████████████████    //
//        ██▌▒▒▓▒▒╗▓▒▒▒╙▓V▓▓██▀▒█▌▀▄▄██▒▓▒▒▒▒▀██▌▒▒▒╢▒▒▒▒▀████▒▒▓▒▒▒▒▒▒▒████████████▒╢████    //
//        ███▒▒▒▒▒▒▒▒▒▒╜k│▓█▌▒▒▒▒▀▓▒▒▀▒▓▒▒▒▒▒╢██▒▒▒▒▒▒▒▒▒▒▒▀██▌▒▒█████████████████▀▒▒▒████    //
//        ████▒▒▒╣▒▒▒▓Ñu│███▒▒▒▓▓▓▓▒▒╫▒▓▒▒▒▒█▀╫▒▒▒▒▒▒▒▒▒▒▒▒▒█████████████████████▌▒▒▒▒████    //
//        █████╩╙╜╝▒╝▒E╖▓▌▒▒▒▒||j▓]▌▄╫▄▄█╜▐▀▀█(╠▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████████▌▒▒╢██████    //
//        █████▌      %▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Ñ██▄▓. ║▓▒▒▒▒▒▒▒▒▒▒▒▓███████████████████▒▒▒███████    //
//        ██████▄    (██▌▒▒▒▒▒╫▒╣▒╫╫╢▒▒▒▒Ñ▐██.▄╚┤╠║▒▒▒╫▓▓▀███▀▀█████████████████▒▒╢███████    //
//        ███████▓ (|(███▒▒▒╢▒▒▒▒▒▒▒▒▒╫▓▌▓█▌ ██└│││▄▓▓▀▀▒▀▓▓╙▀▀█▓███████████████▌▒▒███████    //
//        ████████¬||▐██▀  ╙╙╜▒▒▒▒▒▒╝╜╙ ▌║▀█▓█ L▄▒██▀▄▓▀▀▓╩█▄Rº─▀████████████████▒▒▒██████    //
//        ████████M |███- ╓▄▄⌂]└W,Γw.   ▓▐▄█╙▐█╝████▌▒#╜Ök▌╜█▄«─▓████████████████▓▒▒▓█████    //
//        ████████M|(█▀  ╔▌▒▒▒▒▒▒╣▄▄#▒M╖╫ ████¬(█████▌▄┴Q«æ▌º█▒∞▐▓█████████████████▒▒▀▀▀██    //
//        ████████||╓▀  │ ╙▒▒▒▒▒▒▒▒▓▓╫▒▒▒▒▒▓█▀V▐███████▓@▄██▒▀███▓██████████████████▒╫▒▌██    //
//                                                                                            //
//    ---                                                                                     //
//    ^[ [^ascii ^art ^generator](http://asciiart.club) ^]                                    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract KILL is ERC721Creator {
    constructor() ERC721Creator("KIMO'S KONUNDRUM", "KILL") {}
}