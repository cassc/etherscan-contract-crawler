// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paintings by Georgesketch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    |||'__||T|L|[email protected]@@[email protected]@@lllllllllllllll|l||ll|Ll$$    //
//                                                                                        //
//    ,[email protected],;[email protected]$$$$$$$$$$$llllllllll&[email protected][email protected]&$    //
//                                                                                        //
//    $$$$$$$$$$$$$$$$$$$$$$lllllll&[email protected][email protected]$$&lllT||l|[email protected]||lllllllllll    //
//                                                                                        //
//    $$$$$$$$$$$$$$$$$l$&Ml&[email protected]@[email protected]||||'||||[email protected]%@|lllllllllLl    //
//                                                                                        //
//    $$$$$$$$$$$$$$$$$$lLlL|T|[email protected][email protected]$Mlllll|||L_||l||$&[email protected]|lll|l|llllllL    //
//                                                                                        //
//    $$$$$$$$$&[email protected][email protected]@@[email protected]$$$ill|lll%$5|[email protected]@@@@@@@$L|[email protected]@@[email protected]@@@@{$$$lllllllllllllllllll|    //
//                                                                                        //
//    |[email protected]@@@@@[email protected][email protected]@@[email protected]@$$$$TllLW&$lL|j$M$T|s|[email protected]$$L,@@NMM*1&$%[email protected]    //
//                                                                                        //
//    |[email protected]@@@$$$$$$$MMMM$MlL||||||ll*lL`[email protected][email protected]@@[email protected]@[email protected]@@[email protected]@@@[email protected]|llllllllll    //
//                                                                                        //
//    l|l%%%MMMMMW$l'''l' __ _ _'`____,[email protected]@@[email protected][email protected][email protected]$$$$Wlllllllll|llll||||||    //
//                                                                                        //
//    @@@[email protected]@ggwgwg&[email protected]&&@&[email protected][email protected][email protected][email protected]&g*%[email protected]|l|||||    //
//                                                                                        //
//    [email protected][email protected]@@$$$',l&T|[email protected]$$T|$$$&$M$$&[email protected]@[email protected]||||||||    //
//                                                                                        //
//    [email protected]@@@@@[email protected][email protected]@[email protected]||[email protected][email protected]@@|[email protected]$` |"T||[email protected][email protected]|lllll||||||||    //
//                                                                                        //
//    [email protected]@@[email protected]@[email protected]@@[email protected]|[email protected]@@R$$&$W, _||[email protected]@M|lllll|l|||l||||||    //
//                                                                                        //
//    [email protected]@@[email protected][email protected][email protected]|L|||[email protected]@[email protected]@[email protected]@@@@L;[email protected]@$MllLlLl|l|||||||wl||    //
//                                                                                        //
//    [email protected][email protected]@[email protected][email protected]@[email protected]@L|@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected][email protected]$lllLlLlLlLllL||||||||    //
//                                                                                        //
//    [email protected][email protected][email protected]@@@@[email protected]@$$$$$$$l$$$$$$$$#@@[email protected]$$$&}&[email protected]@@[email protected][email protected]$$Tlllll|l|lll|l|||||||||    //
//                                                                                        //
//    [email protected][email protected]@@@[email protected]@[email protected][email protected]@@[email protected][email protected]@@@@@[email protected][email protected][email protected]|lllll|lllllll||||||||||    //
//                                                                                        //
//    @@[email protected]@@@@@@@@@@[email protected]$$$$$$$$$$$$$$$$#@@@@@$$$$M{lll$%[email protected]@@@|llllllllll|l|llll||l|||ll    //
//                                                                                        //
//    @[email protected][email protected]&M$T|l%[email protected]@[email protected][email protected]@@@@@@@@@@@[email protected][email protected]@@@@$$llLllllllLl|lllllllllll|    //
//                                                                                        //
//    @[email protected][email protected]$l$llll][email protected][email protected][email protected][email protected]@@@@@@@@@@@@@@@@$$$$$$$lllllllllllllllllllll|    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract PG is ERC721Creator {
    constructor() ERC721Creator("Paintings by Georgesketch", "PG") {}
}