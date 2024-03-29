// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lexy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ██████▌,╓╕▓▓▓▓▓▓▓▓██████████▄,                      _    _░▒╖_, ╟▓▓▒▒▄,,,╓▄▄▄▄▄▄    //
//        ██▀▓▄▄▓▓▓█▓▓█▓▓▓▓▓███████████▓▄                   _    _   ╢U_ ░▓████▓▓▓▓▓▓▓▓▓▓▓    //
//        φφ▄▓▓▓▓█████▓▓▓▓█████████████▓▓▓      _  _   _    '░__  `],▓`__╠▓▓████▓▓▓▓▓▓▓▓▓▓    //
//        ▓█▓▌███████▓▓▓▓▓████████████████▓H¿__     *²*`          ╓╫▒▓U, ╟╫█████▓▓▓▓▓▓▓▓▓▓    //
//        ███▓▐███▀╣▓▓▓▓▓▓█████████████████▓▄╖╖╖_                ,░▒▒▒▒▒ ║▓█████▓▓▓▓▓▓▓▓▓╣    //
//        ██▓╣▀██▓╣▓▓▓▓▓▓▓█████▓▓▓▓▓▓▓╣╢▓▓▓▓▓▓▓▓╖,_                _````]╠█████▓▓▓▓▓▓▓▓▓╜"    //
//        ███╣▓▓▓▓╣▓▓▓▓▓█▓▓█████▓▓▓▓╬,,╓▒██████▀▀╜╜N,_           ╓ ,▒╖╖g▓▓▓▓▓▓▒▀"````````     //
//        ████╣▓▓▓▓▓▓▓▓█▓▓▓████▓███████▓▓███▀▀  ,╥*__`@╥╖      ╓▒╖╖╥@▓█▓▓▓▓▓╣╣▒[              //
//        █████▓▓▓▓▓▓▓█▓▓▓▓╣▒▄█████████▓▓φ@╖,,,``  __,,░░╢▓w ╓▒╓▄▓▓▓▓██▓▓▓▓▓╣╣▒`              //
//        ██████▓▓▓▓█▓▓▓▓▓▓▓█████████▀]▓▓▒▒╥╢Ñ▒▒▒▒▒▒]▒╫╣▓╬▓▓▓g▓▓▀▀`╙__ ╫H '╙╙▓║_              //
//        █████▓▓▓████▓▓▓▓▓▓███████▀  ▓▓███▄▓▓▓█▓▓▓╣╢╢╣╣░╙╢▓▓▓▓▓▓╖╓&Ww╓@╬%M__  __             //
//        ████▓▓████████▓▓████████╜┌`▓▓▓╢▓█▓╠▓████▓▓▓▓╨░`` _`▀▓▓_ ]__ ,╢▄,,g▓▓█████▄          //
//        ███▓███████████████████▌_▒g▓▓▓▓▓▓▓▓████▓▓╜"__         ╙▓▓`,▓▓▓▓▓╣▓████████▓▌        //
//        ██████████████████████▓▒╜░║╢▓▓▓▓▓████▓▓╜'   _          ]▓▓██▓▓▓▓█████████▓╢▓▓▄_     //
//        ███████████████████▀╙░_`' _  __ _       __  `__      ,µ▓▓▓▓▓▓███████████▓▒▓▓▓▓▌     //
//        ██████████████▓███╜╜`                 _ '_ _ _    ,╓║╫▓▓▓▓▓▓█████████▓▀▒░▒▓▓▓▓▓_    //
//        ██████████▓▓▀█▀   ,╓╖,,,,╓,  »╖      __    ,╖╖╖╖╖╓@╫▓▓▓▓▓▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▀╣    //
//        ████████▀▒▓╜_  ,╖à▓▓▓▓▓▓▓▓▓▓╣@▒_    _    ░╓▄▓▓▓▓▓▓▓█▓▓██▓▓█▓████▓▓▀║▓▀▀▓▓▓▓▀▓▌ ║    //
//        ███████▒▓"   ╓p╣▓▓▓▓▓▓▓▓▓▓██▓▓╕ ╓    __  ▓██████████████████▀_██████▌__ ,▓▓▄╜ á╣    //
//        ██████▀_   ┌,╫▓▌██████████████▓▓g╟▓╖▒   ╟▓██████████▓███████▓██▀▀████w▄█▀▀█▀,φ▐▓    //
//        ██████_  _╓╓▒╫▓█████████████████▓╣╜'░╓@@█████████████████▓▓███,╓,╫▒▒▓█▓▓▄`▌]▓░▓▓    //
//        ██████▄▓H▒▒╫@▓▓██████████████████▌. ╣▒╫█████████████████▓▒▄████▓▓▓█████▓╢Ñ▒╥╬║▀▓    //
//        ████████▓▓▓▓▓▓▓██████████████████╣`║▒▓█████████████████████████████▀▀▒▒▒@╢╬╣╣╢╨▒    //
//        ████████▌▓▓▓▓████████████████████▒@▓██████████████▓,,▓▓██▌▒▒▒▀▀▒▒╢╫╣╢▒▒▒▓▓▓▓▓╣▓╣    //
//        ▓████████U╙▓████████████████████▒╫████████████████████▓▓▓▓▓╣▓▓▓▓▓▓▓▓▓▓` _`▀▀▀▀▀     //
//        ███████████▒_▀██▓███████████▓▓▓▒╫██████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄,   __      //
//        ████████████▄¿╟███████████▓▓▓▓▓▓▓▒▓██▓▄▓███████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓,   ,    //
//        ████████████████████████▓▓▓▓▓██▓██████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▒╖▒`    //
//        █████▓▓▓▓███████████████████████████████████████▓▓▓▓▓▓▓▓U▓▓▓▓▓▓▓▓▓█████████▓▓▓▓▓    //
//        ██▓▓▓▓▓╣▓█████████▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▀╣▒▒╣Ü╬▓▓▓▓▓▓███████▓▀▓▓▓▓▓▓▓▓    //
//        ███████▓╢╣▓▓▓▓▓▓█████▓▓▓▓▓▌█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀▒░┘_▒▒▒║╥┘▓▓▓▓███████▓▓▓▓▓╩,▓▓▓▓▓▓▓    //
//        ██████████▓██▓▓█▀█▓▓▓▓▓▓▓▌█▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╢▒╜╓@╓ò╔║▓▓╨▓▓▓██████▓▓▓▓▓▓▓▓▄▓▀▓▓▓▓▓▓    //
//        ████▓▓███▓██▓▓ `]▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▀ ╔▓╫╢╝▓▓╣╣╬▓╣▓▓╢`g████████▓▓▓▓▓▓▓▓▓▓▓▓▓M▐▓▓▓    //
//        █▓▓████▓▀▀▒╔▓▀ `▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓æ▀_ ╓╣╢▓▓╗╣╣▒╫▓▓▓▓╣╙`▄███████▓▓▓▓▓▓▓▓▓▓▀,▄▄▓▓▓▓▓▓    //
//        ████▓█▀_╜`_`  ' ▐▓▓▓█▓▌█▓▓▓▓▀╛__ _╔▓▓╫▓▓▓▓▓▓▓▓▓▓╜__█████▓▓▓▓▓▓▓▓▓▓▓_▄▓▓▓▓▓▓▓▓▓▓▓    //
//        ██▓██`   _ ┌┌─'__▓▓▓▓▌▓▓▓▓█_~_ ,,â▓╣▓▒╬▓▓▓▓▓█▀╙▒r╓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌'▓▓▓▓▓▓▓▓▓▓▓    //
//        █▓▓▀_ _   _  :__╠]▓▓▌▓▓▓▓▀_; `,╟╢║▓▓▓▓▓█▓▓██▒▒╝,▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓█▄▄"▀▓▓▓▓▓▓▓    //
//        ▓▓"_   _` ___ _╓╟▓▓▌▐▓▓▀╥m▒╥▒▒%╠╣▓▓▓▓▓▓███▒▓▀╔▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄▄▄▄@    //
//        ▓▓▓▌__  ░ _    `▓▓▓▓▓║,▓▓▓▓▓Å╓▓▓▓▓▓▓████▓▓▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀╓▄▄▄▀▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓▓▀ . _ _____ '▐▓▀▓▓Ñ╓▓▓▓▓▓╜╢▓▓▓▓▓████▓▓▓▓▓▓▓▓▓▓▀╓▄▓▀▀█▓▓▓▓▓▓╓▓╢▓▓▌]▓▓▓▓▓▓▓▓▓▓▓▓    //
//        ▓  ,]_`_ __ .╖_█▓▐▓▀▓▓▓▓▓▓▓▓▓▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▌▐█▓██▓▓▄▄▓▓▄▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▀▀"▀    //
//        M   ░ __ _╓╢╢▓j▓/▓,▓▓▓▓▓▄▓▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▌▓▓▓▓▓▓▓╢▓▓▓▓▓▓▓▓▓▓▓▄▓æ_▓▓▀,@▓▓▓▌    //
//         ░_ ``__ ╖▒╣▓▓╟╓▀╓▓▓▓▓▓▓▓█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓█▓]▓▓▓▓▓▀" `╙▓▓▓▓▓▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓_    //
//           _   ╔▒╫╣▓▓)▌`▓▓▓▓▓▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓L▓▓▓▓_      ╟▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌_,    //
//        _    ╓▓▒▒▒▓▓▌╝,▓▓▓▓▓▓███▓▓▓██▓█▓▓▓▓▓▓▀▀▓▓▀▀▀▓▓▀▀▀,▓▓_Lexy    ╙▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//         _ ╖╬╟╣@▓▓▓▌╟ ▓▓▓████▓╣╢▓▓███▓▓▓▓▓▓▓▌▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓[           ╙▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//        _     _'_   _ ___ _`````"╙▀█▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌                 `_╙▀▀▀▀▀▀▀    //
//                          _         `╙▓▓▓▓▓_▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓_                 _     ___     //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract LXY is ERC1155Creator {
    constructor() ERC1155Creator("Lexy", "LXY") {}
}