// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Checks by DiamondHandsNFT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                        **    //
//                                                                                                                                                       :@+    //
//                                                                                                                                                       *@.    //
//                                                                                                                                                      [email protected]#     //
//                                                                                                                                                 -:   [email protected]:     //
//                                                                                                                                            .-*%@@-   %%      //
//                                ..:-==+**                                                                   :.              :=          .-*%%*#@*.   [email protected]=      //
//                   .:--=+**#%%%%#**+#@@*:                                        .                          [email protected]*    +%   .-*@@%      .=*%%+- .#@-   :[email protected]@*      //
//     .::-=++*##%%%##*+==-:..      =%%=   .                                     -%@+     [email protected]*         :+%+    [email protected]:  [email protected]#.=#%*[email protected]=  :=*%#+:    [email protected]*  :+%#=..#%:    //
//    +#*++=-::.                 :*@*:    .#=              .=*%*              [email protected]#*@-   :#@*@*     .=#@#%@.    *@.  [email protected]@%+:   %@+#%#+:       #@=:+%%=.     =-    //
//              +:             -#%=.      :            :+#%@@@=             :*@*. *@. =%%=  @*  :+%%+-  %@    [email protected]=   --.     :%#=:           :*@%=.              //
//             *@.          [email protected]#-        *@:      .-+%%*=:[email protected]#.  :+-       -#%=    %@*@*:   [email protected]%*%#=.     [email protected]#=+%%-                                                //
//            [email protected]=         -#@+.         [email protected]=   :=*%%+-.  :#%- :+%#[email protected]+   .+%#-      @@+.      #*-           -=-.                                                  //
//            @#       .+%#-           [email protected]#-+#%#+:      [email protected]*.=%%+.  :+  .%*:                                                                                      //
//           *@.     :#@+.             %@%*=.          -*@@+:                                                                                                   //
//          [email protected]=    =%%=                ..                                                                                                                       //
//          @#  :*@*:                                                                                               [email protected]                                         //
//         *@:=%%=                                                                                                  %%                                          //
//        [email protected]@@*:                                -.         #@                                                      [email protected]=              :++                         //
//        %%+.                                 *@:        [email protected]                                                      #@            .=%@@-                         //
//                                            [email protected]=        [email protected]+                                                :=*   [email protected]+          -#@[email protected]+                          //
//                                           [email protected]*        [email protected]#        :-+*:                                :+#@@@=   [email protected]       :*@*-  #@+:                         //
//                                           %%         #@.  :-+#%%%@@=         .      .=*-         :+#%*[email protected]#.   [email protected]#     .+%#=      .=#@*                       //
//                                          *@:        *@%#%%*[email protected]*   ..     :@=  :+%%@@:    .-+%%*=. .#@-   -*@#@+ .=%%+. .#**+==--#@-                       //
//                                         [email protected]=  .:=+#%@@*-.     [email protected]#: .+%%@=    #@=*%#[email protected]# .-*%%*-.    [email protected]*. -*@*-  :%%@+:     .::--=++=                         //
//                                        :@@*#%%*[email protected]#      :#%-.=%%+. [email protected]+  :@@*-    [email protected]#%%+-.       [email protected]#-*@*-       :                                          //
//                                  .-=*#@@%=:.      %%       -%%%%+:          .       ++-             :+*-                                                     //
//                              .*%%#*=:.*@.        *@:         .:                                                                                              //
//                               :      [email protected]        .%=                                                                                                          //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PPDH is ERC1155Creator {
    constructor() ERC1155Creator("Pepe Checks by DiamondHandsNFT", "PPDH") {}
}