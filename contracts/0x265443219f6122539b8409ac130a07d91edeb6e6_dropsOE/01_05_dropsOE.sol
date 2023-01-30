// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Drops - Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                      .+####%,                                                                              //
//                     ,#+.   ,#%.                                                                            //
//                    ,@.  .    :#           .#,                                                              //
//                    #,  #@:.%: %:         .#+                                                               //
//                   :+  :##:+%# .#        .#+                                                                //
//                 ,.#. ,#@: #@:  #.      [email protected]:                                                                 //
//                 %#[email protected]@#@, +M:   %#%    ,@:                                                                  //
//                  :+   :##%+%:+#@%    ,@,                                                                   //
//                  +:    ,.  ++:.,%    +,                                                                    //
//                  #.            .#                                                                          //
//                  @  + ,, % ,:   @      .:::::,     ,:::::::: ::,   .::. :::::::.                           //
//                 .#  @ :+ @ :+   %,     .+++++,     #[email protected]#   ,MM: MMMMMMM+                           //
//                 :+  @ :+ @ :+   +:                 #@@[email protected]@@ @M#   ,MM: [email protected]@@@:                           //
//                 %,  @.++ #:%+   ,%                    #[email protected]    @M#   ,MM: MM%                                //
//                .#   ,#%. ,%+     @.      .            #[email protected]    @M#,,,:MM: MM%....                            //
//                ++                +:      [email protected]%:         #[email protected]    @MMMMMMMM: [email protected]                            //
//               [email protected] .,:+%%###%%+:, .#       .,:         #[email protected]    @MMMMMMMM: [email protected]                            //
//               %:.#@%+:,,,.,,,:+##.+:                  #[email protected]    @M#...,MM: MM%....                            //
//              :#[email protected],              ,#[email protected]                 #[email protected]    @M#   ,MM: MM%                                //
//             ,#.%:                #.,#.                #[email protected]    @M#   ,MM: [email protected]@@@:                           //
//             #, @.                #. :%                #[email protected]    @M#   ,MM: MMMMMMM+                           //
//            :%  @                 #.  #,               ,::    ,:,   .::. :::::::.                           //
//    .+,     %,  #.                @.  :+                                                                    //
//    .:#@,   #.  #,                @   :+             ,,,,,.    .,,,,,,.     .:++,    .,,,,,,    .:++:.      //
//       .    +:  ++               ,#   +:             @MMMMM%.  :[email protected]:   [email protected],  [email protected], ,@MMMMM:     //
//            .#. [email protected]:             .#,   #.             @[email protected] :MMMMMMMM. %MMM#@[email protected] +MMMMMMM#[email protected]##MMM,    //
//             :#. .##+:,.   ..,:%@,   :%              @M# .:MM% :MM,  +MM,,[email protected]  :MM% +MM.  %MM,MM%  ,MM+    //
//    %%%%%:    :#:  .:+%#@@@##%+,    ,@.              @M#   %MM :MM:..%MM,+MM:    #MM +MM...#MM.MMM%:.       //
//    :::::,     .%#:.               :#.               @M#   :MM.:[email protected] %MM.    +MM.+MMMMMMM% +MMMMM#:     //
//                 .+##+,         .:#+.                @M#   :MM.:[email protected] %MM.    +MM.+MMMMMM%.  .+#MMMM+    //
//           %,       [email protected]@@#+:,,:+##+.                  @M#   %MM.:MM:.%MM. +MM,    #MM.+MM,,,.  .,,.  :[email protected]    //
//         .#%        #+  .:++++:#+                    @M# .:MM# :MM, ,MM: ,MM#.  :MM# +MM.     :MM%  [email protected]    //
//        .#+        %+           %:                   @[email protected], :MM,  @M#  %[email protected]%#MMM, +MM.     [email protected]@#@MM%    //
//       .#+        +%            .#,                  @MMMMM#,  :MM,  +MM, .%[email protected],  +MM.      ,@MMMMM#.    //
//      [email protected]:        ,#              [email protected]                 :::::.    .::.  .::,   ,+++:.   ,::         ,+++,      //
//     [email protected]:         #.:.           ,,:%                                                                        //
//     %,         :%+#            [email protected]:#.                                                                       //
//                %#M:             %@#:                                                                       //
//                .:#.             :%:.                                                                       //
//                  #     .::,     .#                                                                         //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract dropsOE is ERC1155Creator {
    constructor() ERC1155Creator("The Drops - Open Edition", "dropsOE") {}
}