// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Create Your Own Galaxy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//           ,gggg,          ,[email protected]            @@              [email protected]            ,ggg,    ,     //
//         [email protected]",ggg"BW       @",[email protected] "@          ,@@,         ,,,[email protected]@@Npgg      @P`   "%@@*[email protected]    //
//        [email protected] #P  "@C$K     $P]@  @F ]@      [email protected]****[email protected]     %@@@@@@@@@P`     @P       ]@@"     //
//        [email protected]  ,     @K     $L]@    ,@      [email protected] * m   ]@       ]@@@@@@@      ]@b    ,[email protected]@@       //
//         %@,    ,@P       Bg "MM*`        [email protected]@@@@@[email protected]       @@@[email protected]@@@    gP"@[email protected]@$,@P        //
//           "MRMP"          "[email protected]@P        @`  ]@   N      'R"    `*[email protected]  "MM*"``"""`          //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract CYOG is ERC1155Creator {
    constructor() ERC1155Creator("Create Your Own Galaxy", "CYOG") {}
}