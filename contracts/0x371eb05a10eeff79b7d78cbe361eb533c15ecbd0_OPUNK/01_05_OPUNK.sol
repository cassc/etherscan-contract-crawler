// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OddPunks - Created by WhichWitchWasIt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                @@@ @@  @  @ "     $ , $    -                               //
//                       &       [email protected]@@   @    @  F    $                                        //
//                     @@$       [email protected]@@@  @@   $        , 1            @ Z                      //
//                  J       p      [email protected]@@$ @          @   7       j  @  @@          [email protected]@@P       //
//        Z                       @$  @        ,    @ @ 8     ` @ @@@  B          @@@@        //
//        JP       $          +  [email protected]    @         @    @      / @@@ $      S     *[email protected]@@@@       //
//                   @@@           @ $   @   @@ @@@ @@@   @ $ @ @ @   J          [email protected]@@@@ZZ     //
//              Z     @@   $      @   $    @  @@@ @@@ @ @@@  @   @@@             [email protected]@@@@ @@    //
//                 @@   @                @ [email protected]@@@@@ @@ @@ @  @  @@@@@  <   J      [email protected]@@@@B @    //
//        @@@@@@@ @@@@[email protected]@ [email protected]            @@@ @  @@ @ @  @ [email protected][email protected]@@@ @@@       @  @@@@@@@@@@@     //
//        @[email protected]@@@@@@@@@@@@@ @@@   P   @  @  @@@@@@@@@@@@@@@ $ @@@@  @ Z-    @@@[email protected]@@@@@@@@@@    //
//                  @  @@@@[email protected]@@       $ @@@@@@@@@@@@@@@@@@@@@   @@@ | @  @@[email protected] @ @@[email protected]@@@@@@    //
//                     @      @  8   @@@@@@@@@@@@@@@@@@@@@@@@@@     @@@[email protected]@@@     @@@@@@@@@    //
//         @@@@@@@@@@$   @    @@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@    [email protected]@@@@    @  @@@@@@@@    //
//         @@@@@@@@@     @@   @@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @ [email protected]@          @@@@@@@    //
//         @@@[email protected]@@       @@   B T @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @  @&         @@@[email protected]$    //
//         @ @@ @          [email protected]     @@@@@@@@@   ZZ+,|  @[email protected]@@@@ @@@@@@  @B   @         @  B      //
//        @@ @  @@@                @@@@@@@@  ''`        @@@ F @@  @@      @[email protected]@@@@@@@@@@@@@    //
//        @@@@@@@$ @       4 B  @  @@@@@@@@@          @@@@@@  @@@[email protected]@   P $$  [email protected][email protected]$ @@[email protected]@@@    //
//         @@@@[email protected]          &    @ @  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@   @@     @@    @@    @@ @     //
//        @@@@@@           P  , @@    @@@@@@@@@@@@@@@@@@@@@@@@@   [email protected]     [email protected][email protected]@@@@@@@@@@@@@    //
//         [email protected]@@@             , [email protected]@ @   @@@@@@@@@@@@@@@@@@@@@@@  @ @@  &  @@@@@@[email protected]@@@@@@@@@    //
//        [email protected]@[email protected]   $    [email protected]@     @@@    @@@@@@@@      [email protected]@@@@@@@@@   @@@@   @@@@@@@@@@@@@@@@@    //
//        @@@@@@  S    @[email protected]   @@@@@@  @@ @@@@@@ -- '-|  @  @@ @@@  @@@@@@ [email protected]@@@@@@@@@@@@@@@    //
//        @@@@    Z    @@@  @@@@@@@@@@@@@ &$ @        [email protected]    @@@@@@@@@[email protected]@ @@@@@@@@@@@@@@@@@    //
//         @      Z     @@  @@@@@@@@@@  2  | @ g,g,,,g        @@@@@@  @@ @@@@@[email protected]@@@@@@@@@@    //
//                $        P @@@@@B g,,gg$  @@@                    @@@@  @[email protected]@@@@@@@@@@@@@@    //
//                          P  @@@                                 @@@   @[email protected]@@@@[email protected]@@@@@@@@    //
//                S      @      @@  [email protected]                            @@     @@@@@@@[email protected]@ @@@@@@    //
//            $7T$;Z     @               @@@@  @@@@@@@@@@@@        @T  Q                      //
//                                                           @@                               //
//                                          @@         @@@@@@                                 //
//                                      @@@@@@@@@@@@@@@@  @@                                  //
//                                       @@@@@@@@@@@@@@@@ [email protected]@                                 //
//                              @@@     @@@@@@@@@@@@@@@@@  @@@    @                           //
//                        @@@@@@@      @@@@@@@@@@@@@@@@@@ [email protected]@@@    @@@@@@                    //
//                                                                                            //
//    ---                                                                                     //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract OPUNK is ERC721Creator {
    constructor() ERC721Creator("OddPunks - Created by WhichWitchWasIt", "OPUNK") {}
}