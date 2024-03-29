// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Think About
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//             ████████████████████████████╣▓▓███▀██████▓╣███████████████████████████    //
//             ████████████████████████▀▀▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▀▀███████████████████████    //
//             █████████████████████▒▒▒▒▒▓▓▓▓▓▒▒▒▒▒▒▒▒▒▓▓▓▓╣▒▒▒▒▓████████████████████    //
//             █████████████████▀▒▓▓▓▓▒▒▒▓▓▓▓▓▌╝╫▒▒▒▒╝▓▓▓▓▓▓▒▒▒▓▓▓╣▒▀████████████████    //
//             ██████████████▀▒▒▒▒▓▓▓▓▓▓▒▒▓╜▒╖┐*▒╢Ñ▒▒▒▒▒%╖╙╩▄▓▓▓╬╣▓▒▒▒▒███▓▓█████████    //
//             █████████▌▒██▒║,║║▒▒▓╣╢▓▓▓,▒░╓M╙░╖╢╬░'`╙▒▒▒░▒░▓▓▓╣▓▓▒▒╢─╚╨▌╢▓█████████    //
//             █████████▌╣▒▒▒▒▒▒╣╢▒▓╫▓▓▀,▒▒╜░░▒─░╨╜╙▒┴▒▒░░ ░▒░▀▓▓▓▒▒▒▒▒▒╢╫▓▓█████████    //
//             █████████▌▒▓▒▒▒▒▒▒▒▒▓▓▓ ╔▒▒░▒╜ @╗ ║▒ ║╢╖░▒░▒▒║▒░▓▓▓▒▒▒▒▒▒▒▓▓▓█████████    //
//             █████████▓▓▓▒▒▒▒▒▒╢▒▓▓▄╢▒╜░[┘╒╢▒▒░░░  ▒▒╢░╙╖░▒▒▄▓▓▓▒▒▒▒▒▒▒▓▓▓▌████████    //
//             ████████▓▓▀@╣▒▒▒▒▒▒▒▓▓▓▓▓▓▓░░╢▒▒╜,▒▒▒, '╢╢ ]▓▓▓▓▀▓▓▓▒▒▒▒▒▒╢▓▓▌▒███████    //
//             ███████▒▓▓▓▓▒▒▒▒▒▒▒▒╜▐╢▒▒▓▓▒░╣▒░▒▒▒▒▒▒▒b ╣h/▓▓▒▒▒░░╢▒▒▒╝╜╨,▓▓▌▒███████    //
//             ███████▒▓▓▓▓▒▒▒▒▒▒▒╜ ╢▒╠╢╢ ▓ ▓▓╫▒▒▒▒▒▓▓╣▓▓▐╣"ÇW╠║╝╗░░║╢╢▒@▓▓▓▌▒▒██████    //
//             ██████▌▒▒▓╣▓▒▒▒╜╢▒▒░]▒▐▌▓░╣▌[▒▒▒▓╣╢║▓▒▌▒▒▒▐▒╫µ▓▓▀╢╢Ñ╢╥à║▒▒╫╫▓▒▒▒██████    //
//             ██████▌▒▒▓╣▓▒╝╙ ▒╫░╓▒░░╫╓▓░╣▒▒▒▒╣╢╣╢▒▒▒▒▒░/╢▒╫░▀▌░╣▒╢▒╢╥`<╩▓▓▒▒▒██████    //
//             ██████▌▒▒▓╢▓╣@▒╝▒░╢▒▒▒ ▒║░╣▒▒▒▒▒▒╣▒▒▒▒▒▒▒▒▒╫╣╢ ▒░╗░║╣▒▒▒▒b/░▓╣▒▒██████    //
//             ███████▒▒▓╢▓╜ ░g▒╢▒▒╓Γ╓║▒U╣╣▒▒▒▒▒╣╫╬▒▒▒▒▒▒▒▒╣╜/ \░╙╖░╝▒╢▒▒▒@ ╙╢▒██████    //
//             ███████Ñ╜`,,q╢▒╝▒╔╢╛▒░▒╣▒U╫▒╣▒▒▒▒╣╣╢▓▒▒▒▒▒▒▓▒╣▒╖»░▒╙╫W░ ╙╝▒▓▓░║▒██████    //
//             ████▀▀ ,m╫╣▓╨▒╓╣▒▒▒▒░╫▐▓▓▓▓▓▓╣╢▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒╢╢▒▒▒╢Ñ╖  `╙╡'███████    //
//             ██▀ ░p▄█▌▓╣@╢▒▒▒▒▒▄╛░▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒║,║▒╣╖, ░`▀█████    //
//             █ /▒███▀▄▓▒▓▌╢╝▀░░░@▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌]▒▒▓▓▓▓░╖░░░▀██    //
//             ░]▓██▀███▌╜░,╓╥@▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓██▓█▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▄▒╣▓▓▓▌██▄╣m░'█    //
//             ░▐████▀▀░╥▒▓▒╫▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓█▓▓█▓▓▓▓▓▓█▓▓▓▓▓▓▓▒▒▓▓▓▓█████▒@░.    //
//              ███▀ ╓╢█▌╫▓██▒▓▓▀░▓▓▓▓█▓█▓▓▓▓▓█▓▓█▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓░║▓▓██▓▓██████╣░▐    //
//             █└▀ ,▄███▌▓▓███▓▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓╣,████▓▓██████▒░█    //
//             ██░╖▓████▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██╬▓█████▀▄██    //
//             █▌░▓███▌╦╙▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀█▀▄█████    //
//             ██░███▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▒▓▓▓▓▓█▓▓▓██▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓█▒╬╣░▒██████    //
//             ███▀▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▒╣╢▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▌▓▓▓▓▓▓▓▓▓█▓▓▓█▓▓╣▓▓▓▄║▒▓████    //
//             ███▓▓▓▓▐▓▓█▓▓▓▓█▓▓▓▓▓▓▓╢╣╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬▓▓███    //
//             ██▓▓▌▀▄▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓╣╢▓▓▓▓▓▓▓╢▓▓▓▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▓▓▓▓██    //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract MIDT22V2 is ERC721Creator {
    constructor() ERC721Creator("Think About", "MIDT22V2") {}
}