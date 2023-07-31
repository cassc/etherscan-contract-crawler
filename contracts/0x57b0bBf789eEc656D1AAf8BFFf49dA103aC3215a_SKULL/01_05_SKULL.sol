// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art of Skull
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//        $$$$$$$$$$$$$$$$$$$$$$$$lllllllllllllllllllllllllllllll$$&$$$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$&$$lllllllllll|||||||||||||||||llllllllll$&$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$lllllllll||||||||l!!'''''!!!l|||||||llllllll$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$llllllll||||||L'  ,=^"'''''"* ~,_ '||||||llllllll$&$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$lllllll||||||!' >"` _,;;!!==!L;;,_ `^, '||||||lllllll$$$$$$$$$$$$$$    //
//        $$$$$$$$$$l$$lllll||||||' ,F__;i|''          `"|!,_'k, ||||||lllllll$$$$$$$$$$$$    //
//        $$$$$$$$$$llllll||||||' y$_;lT|_               __||L,|1, "|||||llllll$$$$$$$$$$$    //
//        $$$$$$$$$llllll|||||| ,$||ll||__                __||lLL|&, ||||||llllll&$$$$$$$$    //
//        $$$$&$$$llllll|||||" gTLll||||__               ___||||l$llg "||||lllllll$&$$$$$$    //
//        $$$$$llllllll|||||" [email protected]$lL|||||___           ____||||lll$l$@ '|||llllllll$&$$$$$    //
//        $$$$$lllllll|||||| j@@|$ll|||||||-_  ________ -||||||ll$$l$$@ ||||llllllll$$$$$$    //
//        $$&$$lllllll|||||` $@$L|$lL|l'''''''___||___"'''''|||ll$Ll$$$ '||||lllllll$$$$$$    //
//        $$$l$llllll||||||` $$&$g|||,,,wggy;,,,,]F,,,,,;,,,,,_|||`$&&$ _|||||lllllll$$$$$    //
//        $&$$llllll|||||||  $@@$$|l@@@@@@@@@$$$@@@$$$$@@@@@@@@g||"@$&$P |||||lllllll$$$$$    //
//        $$$$lllllll||||||  [email protected]$F$$@@&$$$$$@$@$Il'l$$@$@@&$$$$@@L,$@$$P |||||lllllll$$&$$    //
//        &&$llllllll||||||  $$$@=$@$l$''l$&$@@$E _]&$$@$l$'"[email protected]$$$P |||||lllllll$&&$$    //
//        &&$llllllll||||||  $@@_;$@@&L__,$$$@@@$ `]$$$@@&L _,[email protected]`"[email protected] |||||lllllll$$$$$    //
//        &$$llllllll||||||  $$__l$@@@$$$$@$@$$|,@$,|$$$$@$$$$$$@@W _]@P |||||lllllll$$$$$    //
//        &$$lllllllll|||||  @$L '$&@[email protected]$l$T}@@@@ |$l|$@[email protected]  |]@@_||||llllllll$$&$$    //
//        $$$$lllllllll|||L ]@$lL,_'''|&|||&l|L$@@@@@'L|I||"lZT'`,;||$$$ '||lllllllll$&&$$    //
//        $$&$$llllllll||||L $@@$$$$@$$$$$gr$L$$@@@@@g}@g@@$@@$@$$$$$$$P_|||llllllll$$$$$$    //
//        $$$$$llllllllll|||L "$@@@$@@$@$$$@$L$$@@$@@@1W$$$$@@@@$@@@@@`_ll|lllllllll$$$$$$    //
//        $$&&$$llllllllll|||LL_*MMPPN@@[email protected]$|$$$g$$$&J@[email protected]"_|llllllllllll$&$$$$$    //
//        $$$&$$$llllllllll||||[email protected]@ ]@@@@$Il$|$$|$l$l$$$@@ y@@K_;ll||llllllllll$$$$$$$$    //
//        $$$$$$$llllllllllll||||L_$@$L$@@[email protected][email protected][email protected]@$@@,[email protected]|||llllllllllll$$$$$$$$$    //
//        $$$$$&$$lllllllllllll||L_$@$&$$Tj"$ $@ ]P ]P $}Fl@&[email protected]|lllllllllllll$$$$$$$$$$    //
//        $$$$$$&$&$lllllllllllllL @@J@@[email protected]_,L,[email protected]&@[email protected]]@@|lllllllllll$$$&$$$$$$$$    //
//        $$$$$$$$$$$llllllllllllL-$$L$&[email protected] $ L{]F]  ]_g@@$$$|$$P|lllllllll$$$$$$$$$$$$$$    //
//        $$$$$$$$$&$$$$$lllllllllL'%@A$&[email protected]@@@@g@@$W@$$$F$@";lllllllll$&$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$&$$$lllllllll@,$@$ll&$$$W@$$@$&@$$&Tll|$@_l$llllll$$$&$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$$$lllllll&L'&@g|l||$&F  "&$T|l|l$@";$llllll$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$&&&$$$$$llll$&W,*&gg,;[email protected]|g$$P,y$$lll$$$$$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$$$$$$$&$$$ll$$&L"B@@@@$$@@@@@C;@$$$$&$&$$$&$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$$$$$$$$&$$$$&$$&&g||||,,|||,y$$$$$$&$&$$$$$$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$$$$$$$$$$$$&$$&&&$$$$$$$$$$$$&$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract SKULL is ERC721Creator {
    constructor() ERC721Creator("Art of Skull", "SKULL") {}
}