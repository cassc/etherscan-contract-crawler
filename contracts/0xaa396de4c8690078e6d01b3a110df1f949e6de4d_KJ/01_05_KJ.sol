// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kajino
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                               __,                          //
//                               _                     -._                    //
//                                                        ``                  //
//                                                          - "<              //
//                                                              "_            //
//                                                           _`"jj9           //
//                                                    ______   "<jj3~,        //
//                             - __vjj_jj___3;    _<vg$$$p&&6j---\jj99g       //
//                              ``]@[email protected]@$b_vggJ$$$$$$$b669j_ `[email protected]?      //
//                              __J$$$$$B$$$Rbj""%$$$$$$$$Rkk&9([email protected]!     //
//                     _      _g$Rf$$$R$RB$RF`'   `*$RRk$$$$$RB66<j?399(b,    //
//               _,   <|    _J$$B$$$$$R$RP*<           ""R$$$R$$R&pj9396$j    //
//              Jj -  `'  _3"6?""v[**%"`  ___j_j__.       ````]]]]9]30$6O|    //
//              [jj    _  `````         _vJ$$$$$$RRBpj,          "%[email protected]]$    //
//              |J].  _v_               <$$$$$$$$R$$Rb!            <[email protected]@J    //
//              bJ_\_ <9!               `"[email protected]!           __<[email protected]    //
//              93bJj|$b:                 *$$$$$RR$B]              `[email protected]@     //
//               `$&0b$$#.                 jJ9$$$p3("j_             [email protected]"!     //
//                 "%$$$|                 ,[email protected]&j$j,           _6!       //
//                   "@$k,                 "$b%P%%6%?36!j,        """         //
//                     %%%!                           ]jj                     //
//                            '                       <j'/-                   //
//                                   `     -~~   ~- `  `                      //
//    Kajino Peko                                                             //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract KJ is ERC721Creator {
    constructor() ERC721Creator("Kajino", "KJ") {}
}