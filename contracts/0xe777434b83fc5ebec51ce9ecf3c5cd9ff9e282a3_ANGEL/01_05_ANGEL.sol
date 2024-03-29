// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eva Eller Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//        ████████████████████████████████████████████████████████████████████████████████     //
//        █████████████████████████████████████████████████▓███▓██████████████████████████     //
//        ███████████████████████████████████████████████████████████▓████████████████████     //
//        ████████████████████████████████████████████████████████████████████████████████     //
//        ███████████████████████████████████╣▓▓▓██████▓██████████████████████████████████     //
//        ████████████████████████████╣╠╬╣▓▓█████████▓████████████████████████████████████     //
//        ████████████████████████╙╠╠╣╬╬▓▓▓██▓█▓██▓██████▓████████▓███████████████████████     //
//        ████████████████████▀╙≤φ╬╫╬╬╬╬╬╣╬╣▓█▓███████████████████████████████████████████     //
//        ██████████████████╬▄▒╬╠╠╠╬╬╠╬╬╬▓╬╬▓▓▓█▓███▓▓████████████████████████████████████     //
//        ████████████████╬╫╣╬▓╬╬╬╠╣╬╬╣╣╬╣▓╬▓▓▓▓██▓▓██▓████▓██████████████████████████████     //
//        ██████████████▓╣▓╣╬▓╣▓▓▓╬∩╟╣╢╬╬╣▓▓▓▓▓▓▓█▓█▓██▓██████████████████████████████████     //
//        █████████████▓█▓▓▓╬╣▓▓▓▓╬╬╟╬╬╣╬╣▓╬▓██▓▓█▓███████████████████████████████████████     //
//        ████████████▓▓▓▓▓▓▓▓╬╬╣▓▓╬╠╣╣╬╬╬╬▓▓▓▓█▓█████████████████████████████████████████     //
//        ███████████▓▓▓█▓▓▓▓▓▓╣╬╫╣╣╬╬╬╬╣╣╣▓╬╬╠╠╣╣╬▓██████████████████████████████████████     //
//        ████████████▓▓▓▓█▓▓▓╣╬╬╬╬╣╬╠╣╩▒░╠╬╬╬╣▓▓▓▓▓▓▓████████████████████████████████████     //
//        ██████████████▓▓▓▓▓▓▓╣╬╣╬╣▓╬╠▒╬▄▓█▀╙╙ │╙╩╚╠╣╣▓██████████████████████████████████     //
//        ████████████████▓▓╣▓▓▓╬▓╢▓░╬╟▓▀╙    ;  !φ░╬╢╣╣▓▓████████████████████████████████     //
//        ████████████████▓▓▓▓▓▓▓▓█φ╠▓▀`         .╚╠╬╠╬╬▓▓▓███████████████████████████████     //
//        █████████████████▓█▓▓▓▓▓╠╣▓`     ,,,╓▄▒▒╣╬╣╫▓▓▓█▓▓█████▓████████████████████████     //
//        ██████████████████▓▓█▓█░╬▓╙  ,;φ╫╩╚╙╙╙╙ ╙╚╠╬╬╬╣█████████████████████████████████     //
//        ███████████████████▓▓▓▒╬╫▌,╓╩`       ;░▒╠╬╠╠╠╣╣▓╬▓██████████████████████████████     //
//        ████████████████████▓▓╣╬█▓╜  ,,,,≤╓ε░░╠▒╠▒╢╣╣▓▓▓█████▓██████████████████████████     //
//        █████████████████████▓╣╣█  ╔▒╣╬▓▓▓█▒≥░░╠╠╣▓▓██╩╬▓▓▓█████████████████████████████     //
//        ██████████████████████╟╫█ ░╠╩,▄▓▓▄▄╟╬░'░╟▓██╬▄▓▓▄▓██████████████████████████████     //
//        ██████████████████████╣╟█ ╙"▀███▓██▀╩╩  ╟██▓╠▀███▓██▀╣███████████████████████████    //
//        ███████████████████████╣█     ░░▒▒░▒░  ;╠▓█▓╫╬╠╬╣╬╣╣▓███████████████████████████     //
//        ███████████████████████╬█▌   .ε╓▒╠╠░∩ Γ]╚▓▓▓╬▒╠╬╣▓▓╬▓█▓█████████████████████████     //
//        ████████████████████████╣▌  .ƒÅ╠╣▒░▒░ε~ ╠▓▓█▓╣╬╬▓▓█▓▓███████████████████████████     //
//        ████████████████████████▓█  j╠╠▓╣▒░░░   ╠╢▓▓▓╬╬╬▓▓██████████████████████████████     //
//        █████████████████████████╬█µ≤╚╬╬╚░░░░╚▀▓██████╣╣╣╣█▓████████████████████████████     //
//        ██████████████████████████╣█░ ╚░░#▒░░Ω-╙╟▀█▓██▓▓▓▓▓█████████████████████████████     //
//        ███████████████████████████╣█░░╙╠Γ▒╠╠▓▓╝╣██████▓█▓██████████████████████████████     //
//        ████████████████████████████▓█▒░░╠╠▒╬╠╬▓███▓▓███████████████████████████████████     //
//        ███████████████████████████████▄░╚╩╠╠╠╠╩╚╚╬╠▓███████████████████████████████████     //
//        ███████████████████████████████╢█▓▒░╬▒▒▒φ▒╣╣▓███████████████████████████████████     //
//        ███████████████████████████████╣╬╣▓█▓▓▓▓▓▓██████████████████████████████████████     //
//        ██████████████████████████████╟▓█████▓███████████████▓██████████████████████████     //
//        █████████████████████████████▌╩█▓███████████████████████████████████████████████     //
//        █████████████████████████████▌╠│╠╠╣█████████████████████████████████████████████     //
//        ███████████████████████████▀╚░╬║╬╢╣█╬╠████████╬▓████████████████████████████████     //
//        ████████████████████████▀;░φ▒░▒╬╬╢╟▓██████████╣▓███████████████████████████████▓     //
//        █████████████████████▓╙=ó;╙╬φ╠╬╣╬▓╣█▓▒████████╟▓███████████████▓╬╣▓╣╣███████████     //
//        █████████████████╬▓▓╣▒`':'"╚░░╠╩╚╠╣╬▓▒██████▀▀╚╬╚╩╩╬╫▓█▓▓███████▓▓▓▓▓▓██████████     //
//        ██████████▓╬╣▓╬╣▓╣▓▓▓╚░░  Γ░▒╠!░╠╠▒╩▒░╠▒▒▒▒δ░╩╠╠╠╠▒╬▒╣╬▓╣╬╣█████▓▓▓▓▓███████████     //
//        ███████╣╣▓▓▓▓▓╬╬╣▓╣▓>░α.╔░⌠φφ░░ï░▒╬/φφφφ▒"▒▒╠╩▒≤╠╬╬╣╠╬╬╬╬╬╫╬╣█╬▓▓▓▓▓▓██████▓████     //
//        ████╬▓╬╣╬╬╣╣▓╣╬╬╬╣▓█░░»≥[~;Γ▒\Γ░Γ»δ░░φ░░▒╬╝╬╬╬╠░╠╠╢╬╩╬╬╩╬╬╬╢╢╣█▓▓▓▓▓██▓▓▓███████     //
//        ██▓╬▓▓▓╣▓▓╣▓╣▓╣╬╬▓╣▌╚░▒≥]φ░░'-] Γ▒╠▒▒░░░╠░▒Å╠φ▒╠╬╠║╩▒▒╠▒φ╣╬╬╢╬╣╣▓▓▓██████▓█▓██▓▓     //
//        █▓█▓╬╬▓╣▓▓▓▓╬╬╣╣╬╣▓▌"░░Γ⌠φ∩'-Γ≥ :╚░╚╬╠╩▒,█▓╩╚╚░╚╚░╩╬╠▒╬╬╠╬╠╠╢╬╬╣▓╣▓╬▓▓▓▓▓▓╬█╬▓▓▓     //
//        ▓▓▓██▓╣▓▓███▓╣▓▓╣╫▓░]:░\╩". ;GΓ ░░╠▒#╠▒╠░╬░╠░░#╩░φ▒▒╬╠╠╬╠╫╠╠╣╬╬╬╣╣▓▓▓▓▓▓▓╬█▓▓▓▓█     //
//        ▓▓╣╣▓█╣▓╣▓█▓╬▓▓▓▓▓▌▒▒G░╬ε=╓▒φ╚╠░░░Γ░░▒φ░╩░░╠╚Γ░░[░░╠╬▒╠╣╬╢╬╬╣╬╬╬▓▓▓▓██▓▓█▓▓▓▓▓█▓     //
//        ▓▓▓▓▓█▓▓▓▓▓▓╣▓▓▓▓▓▒╠▒/░░░╔╬▒φ▒φ░░▒░░▒░░░#▓▒▒░≥φ░░░░Q╬╠╬╠╬╢╣╬╢╣╬╣▓╬▓███████▓█▓▓██     //
//        ╢╬╬▓╬▓█╣▓▓╣▓╣▓╣▓▓╣▒░╚╠░∩╙ⁿ ΓΓ^╚░╠▒▒╠╠▒▒φφ╠╠╠φ░╬╠▒▒╬╠╬╠╣╠╟╬╣╬╬╬╠╣▓▓▓██▓███▓▓▓█▓▓█     //
//        ▓▓╣╣╣▓██╣▓╣▓╣╬╣▓▓▓▓▓▓▓▓▓▓▓╫▓▓╗╣▒▒▄▄▒▒╠╠╠░╠▒╠░▒░╬░▒░╬╠╬╠╬╬╬╠╬▓╣╫╣▓▓▓╣█████▓▓▓╣▓▓▓     //
//        █▓▓▓╣█▓███▓▓▓▓╣▓▓▓▓▓╬▓╬▓▓╣▓▓▓▓▓╣▓╣▓▓▓▓▓▓▓╬╢╣╣╣▓▓▓▓╫▓▓▓▓╣▓▓╬▓▓▓╣▓█▓▓▓███████▓▓▓▓▓     //
//        ╬█▓▓▓▓▓█▓▓█▓▓▓▓▓▓██▓▓▓▓╣▓▓▓▓▓╬▓╣▓▓▓▓▓▓▓▓▓▓▓█▓▓▓╣▓▓╣▓▓▓▓▓▓▓▓█▓▓██╣▓▓▓█████▓███▓▓█     //
//        ╜╙╙▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀╙▀▀▀▀▀▀▀     //
//                                                                                             //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract ANGEL is ERC721Creator {
    constructor() ERC721Creator("Eva Eller Art", "ANGEL") {}
}