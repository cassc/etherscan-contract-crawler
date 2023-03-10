// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Character Study
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                             ^     `*,      //
//                                                       a#"%@###m      \     //
//         ,#Mm,            ,e#Mm,           s,        ##bb    '```      b    //
//       ;########b      ,##W#######m,    s######m    ### b @##m,     ,s#     //
//     ,"   `[email protected]###     @###b   [email protected]####  ;##[email protected]'%#####  @### b%##########M^      //
//     #     [email protected]###     j###b   bj###b j###[email protected]   ####  @### b   '``,``          //
//    j##mw= [email protected]###     j###b   bj###b j###[email protected]   @###  @### b    ###            //
//           [email protected]###     j###b   bj###b j###[email protected]   @###  @### b   ###b            //
//           [email protected]###     j####3m,bj###b j###[email protected]   @###  @### b   ###b            //
//           [email protected]###     j####@##bj###b j###[email protected]   @###  @### ###m###Q#####m      //
//           [email protected]###     j###b   bj###b j###[email protected] ` @###  @### C*#5####`'`"#`      //
//           [email protected]###,,,  j###b   bj###b j##M @   @###  @### b   ###b            //
//           [email protected]###     V###Q   bj###b A"~"@#p  @###  @### b   ###b    ,s,     //
//           [email protected]#M`     @######mb @###      @   @###  @###,b   ###`     `#b    //
//       s######m,,   ,#^"W######M,,m#MMMMM`   @###  \#####m ,#"        #     //
//     ,#%%%W#########"     '"W`a########      @###   '"@###M,#########       //
//              ````           `               ##"        `.M^``````"^        //
//                                            #"                              //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract LPCS is ERC1155Creator {
    constructor() ERC1155Creator("Character Study", "LPCS") {}
}