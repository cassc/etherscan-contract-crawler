// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Imaginarium Galaxy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬░░░░░░░╬╬░░░░░░░╠╬░░░░░░░░╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬░░▄▀▀▌▄▀▀▄µ╓▄▀▀▄▀▀▀▄░▄▀▀▀▄▀▀▄▄░    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬░░█▄.⌠⌡.▄█╕▐▓▄░⌡~,▄█.█Qµ⌠⌡░▄▓▌░    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬░▀█Q▐█⌠░░░░⌠█░@▌░░░░░█▌,█⌠│░╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╩╩╬╬╬╬╬╩╬╬╬╬╬╬╬╬╬╬╬╬╬╬░░░░╬╩╩░░╩╬╬╬╬╬╬╬░╬▀░╠╬╬╬╬░░▀░φ╬╬╬╬╬░░▀░╠╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬Γj▓▓▌'░░▓▓▌░░░╬╬╬╬╬╬╬░░░▓▓▓' ▄▓▓▓▓▄░░╬╬╬╬╬░░░╬╬╬╬╬╬░░░╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬░░j▓▓▓▓▄ ▓▓▌',▄▄▄▄▄░░,▄▄▄▓▓▓ ▓▓▓▌└▀Γ░▄▄▄▄▄^░▄▄▄,▄▄▄,▄▄▄░░╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬░░j▓▓▀▓▓▓▓▓▌ └▌▄▓▓▓▌▐▓▓▀▀▓▓▓ ╙▀▓▓▓▓▄ ▀▌▄▓▓▓ ▓▓▓▀▀▓▓▀▀▓▓▌░░╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬░░j▓▓▌ ▀▓▓▓▌ ▓▓▌▄▓▓▌▐▓▓▄▄▓▓▓ Æ▄▄▄▓▓▓▐▓▓▄▓▓▓ ▓▓▓ ▐▓▓▌ ▓▓▌░░╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬φ░▀▀░░░⌠▀▀▀,▀▀▀▀▀▀▀,▀▀▀▀▀▀▀,▀▀▀▀▀▀..▀▀▀▀▀▀.▀▀▀,▐▀▀░;▀▀▀░╠╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬░░░░░░░╠φ░░φ░░░░░╠╬╬╬φφ╠╠╠╬╬╬φφ╠╠╬╬╬╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬░▐▄▄░▄▄▄░░░▄▄▄░▄▄╛░░░▄▄░▄▄▄░░╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬░╫▌⌡⌡█╕*▐▓ ▓▌⌡▐█⌡*▓▌▐▓!⌡▀▀⌡j▓░░╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬░░▐█;░;å▌⌠░⌠█▌,░;█▀⌡⌠░█;',▐█⌠░╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬░░▀▓▀░░╠╬╬░░▀▓▀░░╬╬░░▀▓▌░░╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜╜    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract NADSAM is ERC721Creator {
    constructor() ERC721Creator("Imaginarium Galaxy", "NADSAM") {}
}