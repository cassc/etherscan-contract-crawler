// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For the Culture
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                              ,,,wwwwwwwww,                                                 //
//                                     ,,gg%%ll$$$$$$$$$$Tlll$$$$%Mw,                                         //
//                                 ,[email protected][email protected]@@@@@@@@$lll$$%[email protected]@l$$                                        //
//                             ,,wgMM$TTTTTTT%M&[email protected][email protected]$$l$w                                       //
//                         4%[email protected]@@@@WWWWl%$&[email protected][email protected]                                     //
//                        [email protected][email protected]@$$l$$$$$$$$$$$$$$$$$$l$%@[email protected]$$$$$$$]                                     //
//                         [email protected]@[email protected][email protected]$%%$$$$$$$$$$$$$$$$$$$%@$$%@@[email protected]                                    //
//                        gBM%$$$$$M$l$$$$NMTT||"[email protected]*T||*%@@$l%@@[email protected]                                     //
//                       ,.]$$$$&l$$$$$M|||||,wwww,||V||||||||]@$$$$#@$$P                                     //
//                       C%%@@[email protected]|||||||||||||||$$|||||||"*M&[email protected]&*"                                      //
//                        [email protected]$$$$$$$K||||||||,[email protected]%%@[email protected]@%@[email protected]@@[email protected]                                         //
//                         $$$$$$$$#||||||g$$P"[email protected]@$K   'P" [email protected]]K  `"K                                        //
//                         $$$$$$$$$||||||||$Mw,[email protected]`,,~$~,,]$B%.~ym$P                                        //
//                         @$$$$$$$$||||||||||||T**T$%||||,||||,w*l$$L                                        //
//                         j$$$$$$$%|||||||||||||"||||||||||||||"w$$j#                                        //
//                        ][email protected]|||||||;||||||||||||||||||||,W$lj                                        //
//                        ]$$$$$$$$$$||||/  =~==.;,```""^^^^""`- ,g#l%Fk                                      //
//                      g%#@[email protected][email protected]/||==rr=~~,,,,,,--------;,Q{[email protected]@gb                                     //
//                     @$$$$%g$l|[email protected],||||||||||,@MT$lMll$$$$$lh                                    //
//                    ]][email protected]$$$$$l|%Wl$$$$$$lll|%MMM%WWl$$$$$$l$$$$$QF                                    //
//                    [@$$$$$$$l%@[email protected]$$$$$$$$$$M`                                    //
//                   /%MW#[email protected]$$$l%@@[email protected]$l$$$$$$$$$$M#                                     //
//                 ,@[email protected]|[email protected][email protected]$$$$$$$$$$$$$Ml$$g                                    //
//                @[email protected]@[email protected]$l$$$$$&                                   //
//                ""N$%%%%%%%%%%%%$%%%%[email protected]$$$$$lM$$                                   //
//                    "&[email protected]                                  //
//                       %%[email protected]@@[email protected][email protected][email protected][email protected]@]                                 //
//                         %$$$$$$l$%[email protected]|lll|||||ll|[email protected][email protected]$l$K$                                 //
//                           "V$$$$$$$$$$%@[email protected]@[email protected][email protected]"/`                                 //
//                              *g%[email protected]@[email protected]@@M$$$$$$$$$$,P                                   //
//                                "V%%[email protected]$P`                                    //
//                                  `*C*%$$$$$$$$$$$$$$$$$$$$$$$$$$$$P"                                       //
//                                     *N,%$$$$$$$$$$$$$$$$$$$$$$$$*-                                         //
//                                        `*&[email protected]*                                            //
//                                            '"N&[email protected]`                                              //
//                                                  "*****"`                                                  //
//                                                                                                            //
//                                         GIULIO    APRIN                                                    //
//                                         for the culture                                                    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XCULT is ERC721Creator {
    constructor() ERC721Creator("For the Culture", "XCULT") {}
}