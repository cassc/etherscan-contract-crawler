// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT Gardency
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//              $                  @@@@@@@@@&g&@@@l%&,                                //
//              $     ...........  [email protected]$$$$$l$$$$l$g                              //
//              $                  [email protected]|j&,                           //
//              $                  $$$$$$$$$$$$$$$$$&[email protected]&,                         //
//              $                [email protected][email protected]%g~         `    ,       //
//              ]             ,,|''$$$$$$$$$$$$$$$$$$$$$$$$$$$$l&w|L> `. 'L`!L '~     //
//                       ;ww;[email protected][email protected][email protected]||lg,\, "L s,'    //
//              $,,,,,,,[email protected]$$$$$&l$l$$&$$$$$$M$$$$l$l$$$$$$$l&[email protected]|l&glv  *|i    //
//              $LilllLlll$&$$$$$$$|WLll|$$&$$lll$$$$$|l&[email protected]@[email protected]%w'*@w"w      //
//              'l$lllllll&$$$$$$$$||TlL,l|$$$&l$ll$$lll$$$$$$$$$illllll&l|&,"Yg,~    //
//               l$Wl$$$$lll$$$$$$$||l$il|L|[email protected]$ll$lll&$$wl$w'T&    //
//               $$$l$$ll$l$&$$$$$$,>|||Lly|||%l&$lLll$$$$$$$$$$$$$l$$$$$lll&[email protected]*g,    //
//               $$$$$$l$&[email protected]@gl$&gl,il&[email protected]    //
//              ,$$$$$$$ll&[email protected]&Ll|ll$$$l$$$$$$$$$$$$$$$$ll$$&[email protected]    //
//              [email protected]@$l||l$ll&$$$$$$$$$$$$$$$$l$$$&$$$|%&    //
//              ]$$$$$$l$$$|[email protected]|&$$$$$$$$$$$$$$$$$$$$$$$&L    //
//               [email protected]@[email protected]@[email protected]@[email protected][email protected]@@[email protected]&W|[email protected]$    //
//               T&MMM****lll$&$$$$$&[email protected]&[email protected]$$$$$ll$$l&$$&$$$$l$$$$$$    //
//               [email protected][email protected]$$$$$$$$$$TllLl|[email protected]$l&&$$$$$$    //
//               [email protected][email protected]$llllllL'`l$$&$$$$$&l$$llllllLl&$$$$$$$$    //
//               l$&$l|[email protected]$$g|&g|&$Ll|l| |l$$$$$$$l$ll$ll&l|llllLl$&|&$$    //
//               $$Tlllllllll&$$$$$&Lii&@|*LllllT||ll$$$$$$$l$&$$$lllllllllll|[email protected]$    //
//               $$Tllil&ll&[email protected]`  `'`"   '"' |lll$$$$$$$$$$$$$ll$$$&[email protected]$l    //
//               $$ll$$$$$$$$$$$$$$            !l&$$$$$&$$$$$$$$$l$$$$$l$$l$$Wl&$$    //
//               [email protected]$ll$W$$$$$$            ||,'"&$$$$$$$$$$$$$$$$$l$lLlW$$$&gl    //
//               }[email protected]$$$$$$           'L  `.  "&$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//               l$$$$$$$$$$$$$$$$$                      "&[email protected]$$$$$$$$$$    //
//               `|'|||ll|ll|lL,L|,                         "&$$$$$$$$$$$$$$$$$$$$    //
//               !&TiiTi*jl$$$$$$$$                            *[email protected]&@$&$$    //
//               |~.,,..,|ll|,|````                              '*[email protected]    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract NFTGY is ERC721Creator {
    constructor() ERC721Creator("NFT Gardency", "NFTGY") {}
}