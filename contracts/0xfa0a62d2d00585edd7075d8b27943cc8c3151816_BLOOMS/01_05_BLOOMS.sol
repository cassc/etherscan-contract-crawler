// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bloomie Plays
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//     ____  _      ____   ____  __  __ _____ _   _  _______      _______  _____ _____ ____  _   _  _____      //
//    |  _ \| |    / __ \ / __ \|  \/  |_   _| \ | |/ ____\ \    / /_   _|/ ____|_   _/ __ \| \ | |/ ____|     //
//    | |_) | |   | |  | | |  | | \  / | | | |  \| | |  __ \ \  / /  | | | (___   | || |  | |  \| | (___       //
//    |  _ <| |   | |  | | |  | | |\/| | | | | . ` | | |_ | \ \/ /   | |  \___ \  | || |  | | . ` |\___ \      //
//    | |_) | |___| |__| | |__| | |  | |_| |_| |\  | |__| |  \  /   _| |_ ____) |_| || |__| | |\  |____) |     //
//    |____/|______\____/ \____/|_|  |_|_____|_| \_|\_____|   \/   |_____|_____/|_____\____/|_| \_|_____/      //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                             ,@@@@@@ w                              ,gg @@@@ g,                              //
//                          /@@      `[email protected] w,         ,,,,,,,,,ww,,,[email protected]@B  `     @@                              //
//                          @@'        ' ` [email protected]@@@@@@@[email protected] *^"     R `     "' ."@@                             //
//                          ]@@          ~-       "B   j   *$gi    '   ~`       @                              //
//                            [email protected]      ,,     @p             @C     ,,, `   '  @@C                              //
//                             "@@   '        @      ;  '    @,     *  ,:   [email protected]@                                //
//                               [email protected] ,          @      B  `          `      @@"                                 //
//                                @@   .   ,,                 ` `ggw    g  @@                                  //
//                                 [email protected]  ,$]   @@ ,              ,, @@@@ ,   ]@                                  //
//                                 @@>@  @  @@@[email protected] g,      [email protected]@B @@@ ,@NN,s  @@                                 //
//                                 ]@@    N @@@ @@@@       ,@@@ [email protected]@R =g,   @@                                 //
//                                  @@      $"`'  @  , '   ~ @@  `    [  }  @@                                 //
//                                  [email protected]           @@ '#=     @K             @@                                 //
//                                   @@          ]@@         @        @     @@                                 //
//                                    @P        @@@@         @@@     ]  ,   ]@                                 //
//                                     [email protected]      @@@`  @@@@@@  ,][email protected]@        }@@                                 //
//                                     [email protected]     %@       [email protected]  ,~ [email protected]@        [email protected]@                                   //
//                                      [email protected]      @    [email protected]@@@@ '   @     .  @                                    //
//                                       [email protected]    '@., ,   ~-     @                                              //
//                                         @@  l   ,''      l       ; ,    @@                                  //
//                                          @@@ r   .<*[email protected]]k^ ,   @@`    , ,,,,                           //
//                                           @@ `       `*=`'`           '            -                        //
//                                           @ '        ,gw!                   [email protected]@        .                    //
//                                           @  @ ,  ~&          ^  ]B    , .,,                                //
//                                             j          RR         =       '=                                //
//                                                     'B    ,, -.r,,,   .                                     //
//                                                   -]@@=-%rCg]{F                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BLOOMS is ERC721Creator {
    constructor() ERC721Creator("Bloomie Plays", "BLOOMS") {}
}