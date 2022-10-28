// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: elmira_moohel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//    ███████╗██╗     ███╗   ███╗██╗██████╗  █████╗         ███╗   ███╗ ██████╗  ██████╗ ██╗  ██╗███████╗██╗               //
//    ██╔════╝██║     ████╗ ████║██║██╔══██╗██╔══██╗        ████╗ ████║██╔═══██╗██╔═══██╗██║  ██║██╔════╝██║               //
//    █████╗  ██║     ██╔████╔██║██║██████╔╝███████║        ██╔████╔██║██║   ██║██║   ██║███████║█████╗  ██║               //
//    ██╔══╝  ██║     ██║╚██╔╝██║██║██╔══██╗██╔══██║        ██║╚██╔╝██║██║   ██║██║   ██║██╔══██║██╔══╝  ██║               //
//    ███████╗███████╗██║ ╚═╝ ██║██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║  ██║███████╗███████╗          //
//    ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════           //
//                                                                                                ?J                       //
//                                                                                               :&&.                      //
//                                                                                               [email protected]#.                      //
//                                                                                              Y#PB                       //
//                                                                                             [email protected]~GP                       //
//                                                                                            ?&~ &J                       //
//                                                                                           J#~ ^@!                       //
//                                                                                         .PB:  7&:                       //
//                                   7P^                                                  ^B5    5B                        //
//                                 [email protected]@7                                                 ?B!     #Y                        //
//                                :[email protected]^                          .                    ^PP:     [email protected]~                        //
//    ~~~~!!!77???JJJYYYYJJJJJJJJJ#&YB&YJYYYYYYYJJJJJYJJ????777!!?#B7~!~~~~~~~~~^^^::.J&J.      5B                         //
//    ??JJJ??777!!~~^^::^:..::::[email protected]^7B^.::::::::....:::...:::::^:::^^^~~~~!!!77?JJJJG&[email protected]~:                      //
//                   :77?5J.    ^@B^?.     ^Y! ^?5P!  ^7YJ:     .J?     :P7:^!^    ?B!     ....Y&~!?Y5J:                   //
//                 :P#!  [email protected]   7#@#7     :J&@!??^[email protected]?:?!:[email protected]   .7#@7    ~P#[email protected]#^  ^PY.         :&!    .?B?                  //
//                ^&@~ ~5G!  ^[email protected]&!    [email protected]@&5^ [email protected]@5Y: [email protected]   !J#@5   :J?  ~&&^  ?P~           G5       ^&~                 //
//                [email protected]&J?7^  ^[email protected]   .7J^[email protected]@Y   [email protected]&?  [email protected]#. ~57!&B. .7J^  [email protected]&^ ^5J.           Y#         #7                 //
//                !&@!::^!J?^  ^&@?~7J! .&@J   [email protected]~   [email protected]~JJ: [email protected]:7?~    [email protected]~?Y^            [email protected]        ?#.                 //
//                 :7JJ?!^.     :7?7^   :7~    ~!.    .7?~.   :7?!:      .7?!^             ^@Y        [email protected]!                  //
//                                                                                        .#G        :&J                   //
//                                                                                        P&:       ^#5                    //
//                                                                                       [email protected]~       !#J                     //
//                                                                                      [email protected]!      .5B~                      //
//                                                                                     ^@J      !BY.                       //
//                                                                                    .#5     ^PG^                         //
//                                                                                    GG    :YG7                           //
//                                                                                   Y#.  .JG?                             //
//                                                                                  [email protected]^  7PJ.                              //
//                                                                                 ^&7 7PJ.                                //
//                                                                                 B&JGJ:                                  //
//                                                                                ^&BJ:                                    //
//                                                                                 .                                       //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SURREAL is ERC721Creator {
    constructor() ERC721Creator("elmira_moohel", "SURREAL") {}
}