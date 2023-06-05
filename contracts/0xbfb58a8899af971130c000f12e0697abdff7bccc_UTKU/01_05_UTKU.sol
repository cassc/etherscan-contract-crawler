// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UtkuDedetas
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        @[email protected]@@@@[email protected]@@@@@@[email protected]|$$$g|||ll|l|$$$$g|||$|||$$$$|[email protected]@[email protected]@@B$$$    //
//        @@@[email protected]@@[email protected]@@@@@@@@@@@@@[email protected]&[email protected]||l|l|||T$$$g||$g||1$$F]@@@$$$$$$N$'[email protected]$$$    //
//        [email protected]@@[email protected]@@@[email protected]@@@@@@@[email protected][email protected]|||||||||$&@[email protected]"[email protected]@[email protected]|"||||||$$$$    //
//        [email protected]@[email protected]@@@[email protected]@@@@$$$$$$$g|||$&@g||||||||||[email protected]@@[email protected]|||||||||@$$    //
//        [email protected]@[email protected]@@@@@@$&[email protected]@@@@@@[email protected]|||||$&[email protected]|[email protected]@@@$$$&L||||||||||"_     //
//        [email protected]@@[email protected]@@@[email protected]@@@@@@[email protected]|||1&@$$$&[email protected]@@@NMT|||||||||||||| _    //
//        [email protected]@@@[email protected]@@@@@@@@@[email protected]@@@@@@[email protected]||l||$&[email protected][email protected]$||||||||||||||||||||l__    //
//        @@@[email protected]@@@@@$$$RP*""[email protected]@@@@@@@@@@@@$$$$$$$$|lll$$W|ll|||||||||||||||||||||||lL     //
//        [email protected]|`|||___||_%@@[email protected]@@@[email protected]$$W|lllllLLlL|||||||||||||||||L_    //
//        @@@@@@@@@@@$ |||"|L,gL| _ *&@@@[email protected]@@@@$$$&M$'||llllllllllL||||||||||||||||__    //
//        [email protected]@@@@@@@@@ ||`|[email protected]__|||[email protected]@@@[email protected]|L||||||||||llllll||||||||||||||||__    //
//        [email protected]@@@@|| j&$$$l$$L|L|||||||1&[email protected]$L|||l|||||||||||llllL||;|+wwggg$|||L__    //
//        @@[email protected]||_$$$&T||WT_lL|||||||L|||$$|&||||||lL|||||||||||||||T$T|||||||$$L___    //
//        @@@@@@@@@@P||jl$$|||F| ]$I|||||||||||||l||||||||lL|||||||||||ILl|ll&|*[email protected]| ____    //
//        @@@@@@@@@@@_|'L$&l|||&$&&M||||||||||||||l|||||||lllL||||||||ll$&$||W*||||l_ ____    //
//        [email protected]@@@@P|-'Ll&|ll||$$TL||||||||||||||l||||||llllL||||||||||@$l&MF*|||l____ _    //
//        [email protected]@@@|L-'|*[email protected]@||2||||||||||||||||||||l|llllll|||||||||ll|,,,,||||L_____    //
//        @@@@@@@@@@[email protected]||||||$MM*||i|||||||||||||||||l||llllllllL||||||||llllT|||||l_____    //
//        @@@@@@@@@$||$$$QL| _'|||| |L||||||||||||||||llll|||||||||||||||||||T|||||||L____    //
//        [email protected]@L|1$$l$|| ,__ '||||||||||||||||||||llL||||||||||||||||||||||||||||L___    //
//        [email protected]@$|||1$ll$g|J|___|@E|||||||||||||||||||||||||||||||||||||||||||||||||L _    //
//        [email protected]@$F||||[email protected]@gg$$$$L||||||||||||||||||||||||||||||||||||||||lM$&||||||L    //
//        @@@@@@@@l||l|l| 1$$$$$$$$$$$$||||||||||||||||||||||||||||||||||||||||$|lL|||||||    //
//        @@@@@@|lL|||ll|||||&&&[email protected]@|||||||||||||||||||||||||||||||||||||||&|[email protected]|l'_    //
//        @@@@@|llL|||llL||||||||$$$$&[email protected]|||||||||||||||||||||||||||||||||||||||&P"'  ___    //
//        @@@K|lllL||||lL|||||||||$$$$&|$lL|||||||||||||||||||||||||||||||||||||||L_______    //
//        @@K|lll&|||||lL||||l|||||&[email protected]|||||||||||||||||||||||||||||||||||||l&_______    //
//        @K|lll&|||||||L||||ll|||||$llll$&[email protected]|||||||||||||||||||||||||||||||||||l'_______    //
//        R||ll$|||||||||||||l|||||||[email protected]|ll1&L|||||||||||||||||||||||||||@&TL _________    //
//        llll&||||||||||||||ll||||||||&&@$$&g|l&$&||||||||||||||||||||||||||&, ______ ___    //
//        lll&||||||||||||||||l||||||||||&[email protected]||&$$$|||||||||||||||||||||l$&'___________    //
//        ll&|||||||||||||||||ll|l|||||||||[email protected]|||&@&L||||||||||||||||||| ____ ________    //
//        ll|||||||||||||||||||ll||||||||l$'"*l&$$$|ll|1&@g||||||||||||||||| _____ _______    //
//        &||||||||||||||||||||||||||llll& __     '"l&lll|T$&@gg||||||||||||______________    //
//        |||||||||||||||||||||||||lllllL__ _____  ____ '"*&ll||T$Wg|||||||L______________    //
//        |||||||||||||||||||||||llllll'________ ___   __   _ _'*MMMlT&WWlL__ ____________    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract UTKU is ERC721Creator {
    constructor() ERC721Creator("UtkuDedetas", "UTKU") {}
}