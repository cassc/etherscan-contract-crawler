// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Petals & Paws
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                         .*%%#+:    :-=-                                                          //
//             .:-====-:.  %%. .+%= -##==*%:                               :-+*#%%%%#*+-.           //
//          :+%#*==-==+*#%#%%.   +%#%+   :%+          :*-              .-*#*+-:      .-*%#-         //
//        =##=.         :-+*%#    %%=    *%: .-+**+%%%#%%#           :*%*-               -#%=       //
//      :##-         .*%*+++#%%=: %#  .=%%=-#%+-#%%=+*=.=%=.        *%+.                   -%#.     //
//     =%+           +%:      :+%%#%%%#*=+*#%#=  .       =*#%**+-::##.                      .%#     //
//    :%*            .#%+=-:::=#%#-*%=       :%*              :-=*%%#=:                      :%+    //
//    *%.              .-=+%%%+:.#%++##+-:..:+%+                    :=*%#+:                   %%    //
//    %%                 :*%=    #%.  :%%***+=.                         :=*%*-                #%    //
//    #%              .=%%%-   .#%%=   .%*                                  -*%+.            .%*    //
//    =%=           .+%*:=%+.:=%*.#%-   *%                                    .+%+.          *%:    //
//     #%:         +%*.   -+**=:   +%#+*%+                         .....        .*%=        +%=     //
//      #%-      :%#:      -+*##%%%%#=--.                        =%######%#=      -%*.    .*%=      //
//       =%*:   +%+       .%#::::::+%+                           *%+=-----%%       .#%: :*%+.       //
//         =##=##:         =*##***++-                             :-+****+=.         +%%#=.         //
//           :%%:         .-+*##%##*+-.                        .-+#%#***#%%*=:        *%:           //
//           *%:       .=%#+-:.   .:-+%#=                    :*%*-.        :=##-       #%.          //
//          =%=    -#*=%*:      -+***+-:#%-                 +%*+*#%%#=        -%#*%=.  .%#          //
//         .%#    =%%%%=      -%%%%%%%.  *%-               =%%%%%%%%%.  -      :%%%%*   -%+         //
//         +%:    -+*%%      -*%%%%%%%%*#%%#   .:-====--   #%%%%%%%%%%%*%-      #%+=-    *%:        //
//         %#        %%      *%%%%%%%%%%%%%*.=#%+-....-*%*:+%%%%%%%%%%%%%=      %%       :%*        //
//        :%+        =%=     =%%%%%%%%%%%%%#%*:         .+%#%%%%%%%%%%%%%.    .#%:        #%        //
//        =%-         -%*:    -%%%%%%%%%%%%#:   -=+++++-  .*%%%%%%%%%%%+.   .+%*.         +%-       //
//        =%-           =#%+-:..-*%%%%%#*%+    #%+:::=%%.   +#*=#%%%%*--=+*%#+.           -%=       //
//        -%+             .-+**###*+=: -#+   -:.+%#+#%+.:*:  =%-  :-=====-:               -%=       //
//         %#                          %#    %#   *%%:  *%:   #%.                         =%-       //
//         +%-                        =%=    .*%###=+#%%*:    -%+                         #%        //
//          #%.                       +%:                      %#                        -%+        //
//           ##                       +%:                      %%                       :%#         //
//           .%#.                     :%*                     :%*                      :%#          //
//            .#%-                     -%*:                  =%#.                     =%+           //
//              =%*.                    .=#%*++==========+*#%*-                     -##-            //
//               .*#+.                      .:-----===---::.                      :#%=              //
//                 .+%*:                                                       .=##=                //
//                   .=##=:                                                 :=#%+:                  //
//                      :+#%+-.                                         :=*%#=:                     //
//                         .-+#%*=:.                             .:-=*#%*=:                         //
//                              :=+#%#*+==-::........:::--=++*#%%#*+-:.                             //
//    ...............................:-=+*##%%%%%%%%%%###**+==-:................................    //
//    @@@@%#%##%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%#%#%#%@@@    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEPA is ERC721Creator {
    constructor() ERC721Creator("Petals & Paws", "PEPA") {}
}